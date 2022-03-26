use "pony-glfw3/Glfw3"
use "pony-gl/Gl"
use "files"
use "random"

actor Main is (GLFWWindowListener & GLDebugMessageListener)
  let debug: Bool = false
  let env: Env
  let rand: Rand = Rand
  let grid: Grid
  let window: NullablePointer[GLFWwindow]
  let window_user_object: GLFWWindowUserObject
  let vertex_buffer_objects: Array[GLuint] = Array[GLuint].init(-1, 1)
  let vertex_array_objects: Array[GLuint] = Array[GLuint].init(-1, 1)

  var program: GLuint = GLNone()
  var positions: Array[(F32 val, F32 val)] = Array[(F32 val, F32 val)]
  var projection_matrix: Array[F32] = Array[F32].init(0, 4 * 4)
  var mouse_pressed: Bool = false

  new create(env': Env) =>
    env = env'
    grid = Grid(debug, env, this)

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

      window = Glfw3.glfwCreateWindow(320, 240, "Game of Life")
      window_user_object = GLFWWindowUserObject(window)
      window_user_object.set_listener(this)
      window_user_object.enable_key_callback()
      window_user_object.enable_mouse_button_callback()
      window_user_object.enable_framebuffer_size_callback()
      window_user_object.enable_cursor_pos_callback()

      Glfw3.glfwMakeContextCurrent(window)

      Gl.glDebugMessageControl(GLDontCare(), GLDebugTypeOther(), GLDontCare())
      Gl.glEnable(GLDebugOutputSynchronous())
      Gl.glEnable(GLDebugOutput())

      env.out.print("GL version: " + GlHelper.glGetString(GLVersion()))

      let vertex_shader: GLuint = Gl.glCreateShader(GLVertexShader())
      load_shader(vertex_shader, "shaders/default.vert")

      let fragment_shader: GLuint = Gl.glCreateShader(GLFragmentShader())
      load_shader(fragment_shader, "shaders/default.frag")

      program = Gl.glCreateProgram()
      link_program(program, vertex_shader, fragment_shader)

      delete_shader(vertex_shader)
      delete_shader(fragment_shader)

      Gl.glGenVertexArrays(1, vertex_array_objects.cpointer())
      Gl.glGenBuffers(1, vertex_buffer_objects.cpointer())

      Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)
      Gl.glBindBuffer(GLArrayBuffer(), try vertex_buffer_objects(0)? else GLNone() end)

      Gl.glVertexAttribPointer(0, 2, GLFloatType(), GLFalse(), 2 * 4)
      Gl.glEnableVertexAttribArray(0)

      Gl.glBindVertexArray(GLNone())

      draw()
    else
      env.out.print(Glfw3Helper.get_error_description())
      window = NullablePointer[GLFWwindow].none()
      window_user_object = GLFWWindowUserObject.none()
    end

  be draw() =>
    if debug then env.out.print("draw") end
    Glfw3.glfwMakeContextCurrent(window)
    Glfw3.glfwSwapInterval(1)

    Gl.glClearColor(0.0, 0.0, 0.0, 1.0)
    Gl.glClear(GLColorBufferBit())
    Gl.glUseProgram(program)
    Gl.glUniformMatrix4fv(Gl.glGetUniformLocation(program, "projection".cpointer()), 1, GLFalse(), projection_matrix.cpointer())
    Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)
    Gl.glBufferData[(F32, F32)](GLArrayBuffer(), GLsizeiptr.from[USize]((32 / 8) * 2 * positions.size()), positions.cpointer(), GLDynamicDraw())
    Gl.glDrawArrays(GLPoints(), 0, GLsizei.from[USize](positions.size() * 2))

    Glfw3.glfwSwapBuffers(window)
    Glfw3.glfwPollEvents()

    if (Glfw3.glfwWindowShouldClose(window) == GLFWTrue()) then return end

    grid.update()
    draw()

  be add_position(x: F32, y: F32) =>
    positions.push((x, y))

  be remove_position(x: F32, y: F32) =>
    try
      let result: USize = positions.find((x, y))?
      try
        positions.delete(result)?
      else
        env.out.print("Error, could not remove position " + x.string() + "x" + y.string())
      end
    else
      env.out.print("Error, could not find position " + x.string() + "x" + y.string())
    end

  fun _final() =>
    Gl.glDeleteProgram(program)
    Gl.glDeleteBuffers(1, vertex_buffer_objects.cpointer())
    Gl.glDeleteVertexArrays(1, vertex_array_objects.cpointer())

    Glfw3.glfwDestroyWindow(window)
    Glfw3.glfwTerminate()

  fun load_shader(shader: GLuint val, path: String) =>
    Glfw3.glfwMakeContextCurrent(window)
    try
      let file = File.open(FilePath(env.root as AmbientAuth, path)?)
      GlHelper.glShaderSource(shader, file.read_string(file.size()))
      Gl.glCompileShader(shader)
      if (GlHelper.glGetShaderiv(shader, GLCompileStatus()) == GLFalse()) then
        env.out.print(GlHelper.glGetShaderInfoLog(shader))
      end
    else
      env.out.print("Error, could not open " + path)
    end

  fun link_program(target: GLuint val, vertex_shader: GLuint val, fragment_shader: GLuint val) =>
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glAttachShader(target, vertex_shader)
    Gl.glAttachShader(target, fragment_shader)
    Gl.glLinkProgram(target)
    if (GlHelper.glGetProgramiv(target, GLLinkStatus()) == 0) then
      env.out.print(GlHelper.glGetProgramInfoLog(target))
    end

  fun delete_shader(shader: GLuint) =>
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glDeleteShader(shader)

  fun ref key_callback(key: I32 val, scancode: I32 val, action: I32 val, mods: I32 val) =>
    match key
    | GLFWKeyEscape()
    | GLFWKeyQ() => Glfw3.glfwSetWindowShouldClose(window, GLFWTrue())
    end
    if debug then env.out.print("key: " + key.string()) end

  fun ref framebuffer_size_callback(width: I32, height: I32) =>
    let l: F32 = 0.0
    let r: F32 = F32.from[I32](width)
    let b: F32 = F32.from[I32](height)
    let t: F32 = 0.0
    let n: F32 = -1.0
    let f: F32 = 10.0
    try
      projection_matrix.update((0 * 4) + 0, 2.0 / (r - l))?
      projection_matrix.update((1 * 4) + 1, 2.0 / (t - b))?
      projection_matrix.update((2 * 4) + 2, -2.0 / (f - n))?
      projection_matrix.update((3 * 4) + 0, - (r + l) / (r - l))?
      projection_matrix.update((3 * 4) + 1, - (t + b) / (t - b))?
      projection_matrix.update((3 * 4) + 2, - (f + n) / (f - n))?
      projection_matrix.update((3 * 4) + 3, 1.0)?
    else
      env.out.print("Error, could not set projection matrix values")
    end
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glViewport(0, 0, width, height)

  fun ref mouse_button_callback(button: I32, action: I32, mods: I32) =>
    if (button == GLFWMouseButton1()) then
      if (action == GLFWPress()) then
        mouse_pressed = true
      elseif (action == GLFWRelease()) then
        mouse_pressed = false
      end
    end

  fun ref cursor_pos_callback(xpos': F64, ypos': F64) =>
    let xpos = I32.from[F64](xpos')
    let ypos = I32.from[F64](ypos')
    if (mouse_pressed) then
      grid.spawn_at(xpos, ypos)
    end

  fun debug_message_callback(source: GLenum, type': GLenum, id: GLuint , severity: GLenum, length: GLsizei, message: Pointer[GLchar]) =>
    env.out.print("OpenGL Error...")

