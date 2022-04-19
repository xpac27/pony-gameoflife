use "pony-glfw3/Glfw3"
use "pony-gl/Gl"

actor Renderer is GLDebugMessageListener
  let env: Env
  let window: NullablePointer[GLFWwindow] tag
  let program: Program val
  let zoom: GLsizei
  let swap_interval: I32 = 5
  let total_vertex_array_objects: GLsizei = 2
  let total_vertex_buffer_objects: GLsizei = 2
  let total_render_buffer_objects: GLsizei = 1
  let total_frame_buffer_objects: GLsizei = 1
  let vertex_array_objects: Array[GLuint] val = recover Array[GLuint].init(GLNone(), USize.from[GLsizei](total_vertex_array_objects)) end
  let vertex_buffer_objects: Array[GLuint] val = recover Array[GLuint].init(GLNone(), USize.from[GLsizei](total_vertex_buffer_objects)) end
  let render_buffer_objects: Array[GLuint] val = recover Array[GLuint].init(GLNone(), USize.from[GLsizei](total_render_buffer_objects)) end
  let frame_buffer_objects: Array[GLuint] val = recover Array[GLuint].init(GLNone(), USize.from[GLsizei](total_frame_buffer_objects)) end
  let color_white: Array[F32] val = recover [1 ; 1 ; 1] end
  let color_black: Array[F32] val = recover [0 ; 0 ; 0] end 
  let color_red: Array[F32] val = recover [1 ; 0 ; 0] end

  var width: GLsizei
  var height: GLsizei

  new create(env': Env, window': NullablePointer[GLFWwindow] tag, width': USize, height': USize, zoom': F32) =>
    env = env'
    window = window'
    width = GLsizei.from[USize](width')
    height = GLsizei.from[USize](height')
    zoom = GLsizei.from[F32](zoom')

    Glfw3.glfwMakeContextCurrent(window)

    Gl.glDebugMessageControl(GLDontCare(), GLDebugTypeOther(), GLDontCare())
    Gl.glEnable(GLDebugOutputSynchronous())
    Gl.glEnable(GLDebugOutput())

    env.out.print("GL version: " + GlHelper.glGetString(GLVersion()))

    program = recover Program(env, [
      Shader(env, VertexShader, "shaders/default.vert")
      Shader(env, FragmentShader, "shaders/default.frag")
    ]) end

    // TODO create wrapper classes
    Gl.glGenVertexArrays(total_vertex_array_objects, vertex_array_objects.cpointer())
    Gl.glGenBuffers(total_vertex_buffer_objects, vertex_buffer_objects.cpointer())
    Gl.glCreateRenderbuffers(total_render_buffer_objects, render_buffer_objects.cpointer())
    Gl.glGenFramebuffers(total_frame_buffer_objects, frame_buffer_objects.cpointer())

    Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)
    Gl.glBindBuffer(GLArrayBuffer(), try vertex_buffer_objects(0)? else GLNone() end)
    Gl.glVertexAttribPointer(0, 2, GLFloatType(), GLFalse(), 2 * 4)
    Gl.glEnableVertexAttribArray(0)
    Gl.glBindVertexArray(GLNone())

    apply_size()

  fun _final() =>
    /* Glfw3.glfwMakeContextCurrent(window) */ // TODO this crashes because the window object is already removed but is it necessary?
    Gl.glDeleteFramebuffers(total_frame_buffer_objects, frame_buffer_objects.cpointer())
    Gl.glDeleteRenderbuffers(total_render_buffer_objects, render_buffer_objects.cpointer())
    Gl.glDeleteBuffers(1, vertex_buffer_objects.cpointer())
    Gl.glDeleteVertexArrays(1, vertex_array_objects.cpointer())

  be draw(accessor: GridPositionAccessor tag, callback: {box()} val) =>
    // TODO receive an Array of (position, alive/dead) so that we can draw everying in one draw call (black if dead white if alive)
    // this way we don't need 2 arrays and can easily grab the result of our map/reduce methods

    accessor.access({(accessor: GridPositionAccessor ref) =>
      let new_positions = accessor.get_new_positions()
      let old_positions = accessor.get_old_positions()

      Glfw3.glfwMakeContextCurrent(window)
      Glfw3.glfwSwapInterval(swap_interval)
      Glfw3.glfwSwapBuffers(window)

      Glfw3.glfwPollEvents()

      Gl.glUseProgram(program.handle)
      Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)

      Gl.glBindFramebuffer(GLDrawFramebuffer(), try frame_buffer_objects(0)? else GLNone() end)

      Gl.glUniform3fv(Gl.glGetUniformLocation(program.handle, "color".cpointer()), 1, color_white.cpointer())
      Gl.glBufferData[(F32, F32)](GLArrayBuffer(), GLsizeiptr.from[USize]((32 / 8) * 2 * new_positions.size()), new_positions.cpointer(), GLDynamicDraw())
      Gl.glDrawArrays(GLPoints(), 0, GLsizei.from[USize](new_positions.size() * 2))

      Gl.glUniform3fv(Gl.glGetUniformLocation(program.handle, "color".cpointer()), 1, color_black.cpointer())
      Gl.glBufferData[(F32, F32)](GLArrayBuffer(), GLsizeiptr.from[USize]((32 / 8) * 2 * old_positions.size()), old_positions.cpointer(), GLDynamicDraw())
      Gl.glDrawArrays(GLPoints(), 0, GLsizei.from[USize](old_positions.size() * 2))

      Gl.glUseProgram(GLNone())
      Gl.glBindVertexArray(GLNone())

      Gl.glBindFramebuffer(GLReadFramebuffer(), try frame_buffer_objects(0)? else GLNone() end)
      Gl.glBindFramebuffer(GLDrawFramebuffer(), 0)
      Gl.glBlitFramebuffer(0, 0, width, height, 0, 0, width * zoom, height * zoom, GLColorBufferBit(), GLNearest())
      Gl.glBindFramebuffer(GLReadFramebuffer(), GLNone())
      Gl.glBindFramebuffer(GLDrawFramebuffer(), GLNone())

      if (Glfw3.glfwWindowShouldClose(window) == GLFWFalse()) then
        callback()
      end
    } val)


  be resize(width': USize, height': USize) =>
    env.out.print("resize")
    width = GLsizei.from[USize](width')
    height = GLsizei.from[USize](height')
    apply_size()

  fun apply_size() =>
    Glfw3.glfwMakeContextCurrent(window)
    reset_viewport()
    clear()
    reset_projection_matrix()
    reset_frame_buffers()

  fun reset_viewport() =>
    Gl.glViewport(0, 0, width, height)

  fun clear() =>
    Gl.glClearColor(0.0, 0.0, 0.0, 1.0)
    Gl.glClear(GLColorBufferBit())

  fun reset_projection_matrix() =>
    // TODO create wrapper classes
    let projection_matrix = build_projection_matrix(0, F32.from[I32](width), F32.from[I32](height), 0, -1, 10)
    Gl.glUseProgram(program.handle)
    Gl.glUniformMatrix4fv(Gl.glGetUniformLocation(program.handle, "projection".cpointer()), 1, GLFalse(), projection_matrix.cpointer())
    Gl.glUseProgram(GLNone())

  fun reset_frame_buffers() =>
    // TODO create wrapper classes
    Gl.glDeleteRenderbuffers(total_render_buffer_objects, render_buffer_objects.cpointer())
    Gl.glDeleteFramebuffers(total_frame_buffer_objects, frame_buffer_objects.cpointer())

    Gl.glCreateRenderbuffers(total_render_buffer_objects, render_buffer_objects.cpointer())
    Gl.glGenFramebuffers(total_frame_buffer_objects, frame_buffer_objects.cpointer())

    Gl.glNamedRenderbufferStorage(try render_buffer_objects(0)? else GLNone() end, GLRgb(), width, height)
    Gl.glBindFramebuffer(GLDrawFramebuffer(), try frame_buffer_objects(0)? else GLNone() end)
    Gl.glNamedFramebufferRenderbuffer(try frame_buffer_objects(0)? else GLNone() end, GLColorAttachment0(), GLRenderbuffer(), try render_buffer_objects(0)? else GLNone() end)
    Gl.glBindFramebuffer(GLDrawFramebuffer(), GLNone())

  fun build_projection_matrix(l: F32, r: F32, b: F32, t: F32, n: F32, f: F32): Array[F32] =>
    var output = Array[F32].init(0, 4 * 4)
    try
      output.update((0 * 4) + 0, 2.0 / (r - l))?
      output.update((1 * 4) + 1, 2.0 / (t - b))?
      output.update((2 * 4) + 2, -2.0 / (f - n))?
      output.update((3 * 4) + 0, - (r + l) / (r - l))?
      output.update((3 * 4) + 1, - (t + b) / (t - b))?
      output.update((3 * 4) + 2, - (f + n) / (f - n))?
      output.update((3 * 4) + 3, 1.0)?
    else
      env.out.print("Error RD05, could not set projection matrix values")
    end
    output

  fun debug_message_callback(source: GLenum, type': GLenum, id: GLuint , severity: GLenum, length: GLsizei, message: Pointer[GLchar]) =>
    env.out.print("Error RD04, ...")
    // TODO implement... https://github.com/fendevel/Guide-to-Modern-OpenGL-Functions#detailed-messages-with-debug-output
