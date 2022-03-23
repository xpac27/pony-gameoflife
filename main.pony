use "pony-glfw3/Glfw3"
use "pony-gl/Gl"
use "files"

type Position is (F32, F32)

actor Main is (GLFWWindowListener & GLDebugMessageListener)
  let env: Env
  let window: NullablePointer[GLFWwindow]
  let window_user_object: GLFWWindowUserObject
  let vertex_buffer_objects: Array[GLuint] = Array[GLuint].init(-1, 1)
  let vertex_array_objects: Array[GLuint] = Array[GLuint].init(-1, 1)

  new create(env': Env) =>
    env = env'

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


      let vertex_shader: GLuint = Gl.glCreateShader(GLVertexShader())
      load_shader(vertex_shader, "shaders/default.vert")

      let fragment_shader: GLuint = Gl.glCreateShader(GLFragmentShader())
      load_shader(fragment_shader, "shaders/default.frag")

      let program: GLuint = Gl.glCreateProgram()
      link_program(program, vertex_shader, fragment_shader)

      delete_shader(vertex_shader)
      delete_shader(fragment_shader)

      Gl.glGenVertexArrays(1, vertex_array_objects.cpointer())
      Gl.glGenBuffers(1, vertex_buffer_objects.cpointer())

      Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)
      Gl.glBindBuffer(GLArrayBuffer(), try vertex_buffer_objects(0)? else GLNone() end)

      var positions: Array[Position] = Array[Position]
      positions.push((-0.5, -0.5))
      positions.push(( 0.5, -0.5))
      positions.push(( 0.0,  0.5))
      Gl.glBufferData[(F32, F32)](GLArrayBuffer(), GLsizeiptr.from[USize]((32 / 8) * 2 * positions.size()), positions.cpointer(), GLStaticDraw())

      Gl.glVertexAttribPointer(0, 2, GLFloatType(), GLFalse(), 2 * 4)
      Gl.glEnableVertexAttribArray(0)

      Gl.glBindVertexArray(GLNone())

      loop(program)
    else
      env.out.print(Glfw3Helper.get_error_description())
      window = NullablePointer[GLFWwindow].none()
      window_user_object = GLFWWindowUserObject.none()
    end

  be loop(program: GLuint) =>
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

      loop(program)
    else
      Gl.glDeleteProgram(program)
      Gl.glDeleteBuffers(1, vertex_buffer_objects.cpointer())
      Gl.glDeleteVertexArrays(1, vertex_array_objects.cpointer())

      Glfw3.glfwDestroyWindow(window)
      Glfw3.glfwTerminate()
    end

  be load_shader(shader: GLuint val, path: String) =>
    Glfw3.glfwMakeContextCurrent(window)
    try
      let file = File.open(FilePath(env.root as AmbientAuth, path)?)
      GlHelper.glShaderSource(shader, file.read_string(file.size()))
      Gl.glCompileShader(shader)
      if (GlHelper.glGetShaderiv(shader, GLCompileStatus()) == GLFalse()) then
        env.out.print(GlHelper.glGetShaderInfoLog(shader))
      end
    else
      env.out.print("ERROR: could not open " + path)
    end

  be link_program(program: GLuint val, vertex_shader: GLuint val, fragment_shader: GLuint val) =>
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glAttachShader(program, vertex_shader)
    Gl.glAttachShader(program, fragment_shader)
    Gl.glLinkProgram(program)
    if (GlHelper.glGetProgramiv(program, GLLinkStatus()) == 0) then
      env.out.print(GlHelper.glGetProgramInfoLog(program))
    end

  be delete_shader(shader: GLuint) =>
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glDeleteShader(shader)

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

