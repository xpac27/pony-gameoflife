use "pony-glfw3/Glfw3"
use "pony-gl/Gl"

type Position is (F32, F32)

actor Main is (GLFWWindowListener & GLDebugMessageListener)
  let env: Env
  let window: NullablePointer[GLFWwindow]
  let window_user_object: GLFWWindowUserObject
  var program: GLuint = GLNone()
  var vertex_buffer_objects: Array[GLuint] = Array[GLuint].init(-1, 1)
  var vertex_array_objects: Array[GLuint] = Array[GLuint].init(-1, 1)
  var positions: Array[Position] = Array[Position]

  new create(env': Env) =>
    env = env'
    positions.push((-0.5, -0.5))
    positions.push(( 0.5, -0.5))
    positions.push(( 0.0,  0.5))

    if (Glfw3.glfwInit() == GLFWTrue()) then
      env.out.print("GLFW initialized version: " + Glfw3.glfwGetVersionString())

      Glfw3.glfwWindowHint(GLFWResizable(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWDecorated(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWFocused(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWDoublebuffer(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWContextVersionMajor(), 3)
      Glfw3.glfwWindowHint(GLFWContextVersionMinor(), 3)
      Glfw3.glfwWindowHint(GLFWOpenglForwardCompat(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWOpenglProfile(), GLFWOpenglCoreProfile())

      window = Glfw3.glfwCreateWindow(640, 480, "My Title")
      window_user_object = GLFWWindowUserObject(window)
      window_user_object.set_listener(this)
      window_user_object.enable_key_callback()
      window_user_object.enable_framebuffer_size_callback()

      Glfw3.glfwMakeContextCurrent(window)

      Gl.glDebugMessageControl(GLDontCare(), GLDebugTypeOther(), GLDontCare())
      Gl.glEnable(GLDebugOutputSynchronous())
      Gl.glEnable(GLDebugOutput())

      env.out.print("GL version: " + GlHelper.glGetString(GLVersion()))

      let vertex_shader_source: String =
        """
        #version 330
        layout (location = 0) in vec3 aPos;
        void main(void)
        {
          gl_Position = vec4(aPos.x, aPos.y, 0.0f, 1.0f);
        }
        """

      let fragment_shader_source: String =
        """
        #version 330
        out vec4 color;
        void main(void)
        {
          color = vec4(1.0f, 1.0f, 1.0f, 1.0f);
        }
        """

      let vertex_shader: GLuint = Gl.glCreateShader(GLVertexShader())
      GlHelper.glShaderSource(vertex_shader, vertex_shader_source)
      Gl.glCompileShader(vertex_shader)

      let fragment_shader: GLuint = Gl.glCreateShader(GLFragmentShader())
      GlHelper.glShaderSource(fragment_shader, fragment_shader_source)
      Gl.glCompileShader(fragment_shader)

      program = Gl.glCreateProgram()
      Gl.glAttachShader(program, vertex_shader)
      Gl.glAttachShader(program, fragment_shader)
      Gl.glLinkProgram(program)

      Gl.glDeleteShader(vertex_shader)
      Gl.glDeleteShader(fragment_shader)

      if (GlHelper.glGetShaderiv(vertex_shader, GLCompileStatus()) == GLFalse()) then
        env.out.print("ERROR: " + GlHelper.glGetShaderInfoLog(vertex_shader))
      end

      if (GlHelper.glGetShaderiv(fragment_shader, GLCompileStatus()) == 0) then
        env.out.print("ERROR: " + GlHelper.glGetShaderInfoLog(fragment_shader))
      end

      if (GlHelper.glGetProgramiv(program, GLLinkStatus()) == 0) then
        env.out.print("ERROR: " + GlHelper.glGetProgramInfoLog(program))
      end

      Gl.glGenVertexArrays(1, vertex_array_objects.cpointer())
      Gl.glGenBuffers(1, vertex_buffer_objects.cpointer())

      Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)
      Gl.glBindBuffer(GLArrayBuffer(), try vertex_buffer_objects(0)? else GLNone() end)

      Gl.glBufferData[(F32, F32)](GLArrayBuffer(), GLsizeiptr.from[USize]((32 / 8) * 2 * positions.size()), positions.cpointer(), GLStaticDraw())

      Gl.glVertexAttribPointer(0, 2, GLFloatType(), GLFalse(), 2 * 4)
      Gl.glEnableVertexAttribArray(0)

      Gl.glBindVertexArray(GLNone())

      loop()
    else
      env.out.print("Error: could not initialize GLFW")
      env.out.print(Glfw3Helper.get_error_description())
      window = NullablePointer[GLFWwindow].none()
      window_user_object = GLFWWindowUserObject.none()
    end

  be loop() =>
    Glfw3.glfwMakeContextCurrent(window)
    Glfw3.glfwSwapInterval(1)

    if (Glfw3.glfwWindowShouldClose(window) == 0) then
      Gl.glClearColor(0.0, 0.0, 0.0, 1.0)
      Gl.glClear(GLColorBufferBit())

      Gl.glUseProgram(program)
      Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)
      Gl.glDrawArrays(GLTriangles(), 0, 6)

      Glfw3.glfwSwapBuffers(window)
      Glfw3.glfwPollEvents()

      loop()
    else
      Gl.glDeleteProgram(program)
      Gl.glDeleteBuffers(1, vertex_buffer_objects.cpointer())
      Gl.glDeleteVertexArrays(1, vertex_array_objects.cpointer())

      Glfw3.glfwDestroyWindow(window)
      Glfw3.glfwTerminate()
    end

  fun key_callback(key: I32 val, scancode: I32 val, action: I32 val, mods: I32 val) =>
    match key
    | GLFWKeyEscape()
    | GLFWKeyQ() => Glfw3.glfwSetWindowShouldClose(window, GLFWTrue())
    end
    env.out.print("key: " + key.string())

  fun framebuffer_size_callback(width: I32 val, height: I32 val) =>
      Gl.glViewport(0, 0, width, height)

  fun debug_message_callback(source: GLenum, type': GLenum, id: GLuint , severity: GLenum, length: GLsizei, message: Pointer[GLchar]) =>
    env.out.print("OpenGL ERROR: ...")

