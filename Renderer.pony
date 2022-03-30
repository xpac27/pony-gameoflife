use "pony-glfw3/Glfw3"
use "pony-gl/Gl"

class Renderer is GLDebugMessageListener
  let env: Env
  let window: NullablePointer[GLFWwindow] tag
  let program: Program
  let vertex_buffer_objects: Array[GLuint] = [ GLNone() ]
  let vertex_array_objects: Array[GLuint] = [ GLNone() ]
  let color_white: Array[F32] = [1 ; 1 ; 1]
  let color_black: Array[F32] = [0 ; 0 ; 0]
  let color_red: Array[F32] = [1 ; 0 ; 0]

  var projection_matrix: Array[F32] = Array[F32].init(0, 4 * 4)

  new create(env': Env, window': NullablePointer[GLFWwindow] tag) =>
    env = env'
    window = window'

    Glfw3.glfwMakeContextCurrent(window)

    Gl.glDebugMessageControl(GLDontCare(), GLDebugTypeOther(), GLDontCare())
    Gl.glEnable(GLDebugOutputSynchronous())
    Gl.glEnable(GLDebugOutput())

    env.out.print("GL version: " + GlHelper.glGetString(GLVersion()))

    program = Program(env, [
      Shader(env, VertexShader, "shaders/default.vert")
      Shader(env, FragmentShader, "shaders/default.frag")
    ])

    Gl.glGenVertexArrays(1, vertex_array_objects.cpointer())
    Gl.glGenBuffers(1, vertex_buffer_objects.cpointer())
    Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)
    Gl.glBindBuffer(GLArrayBuffer(), try vertex_buffer_objects(0)? else GLNone() end)
    Gl.glVertexAttribPointer(0, 2, GLFloatType(), GLFalse(), 2 * 4)
    Gl.glEnableVertexAttribArray(0)
    Gl.glBindVertexArray(GLNone())

  fun _final() =>
    Gl.glDeleteBuffers(1, vertex_buffer_objects.cpointer())
    Gl.glDeleteVertexArrays(1, vertex_array_objects.cpointer())

  fun clear() =>
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glClearColor(0.0, 0.0, 0.0, 1.0)
    Gl.glClear(GLColorBufferBit())

  fun swap() =>
    Glfw3.glfwMakeContextCurrent(window)
    Glfw3.glfwSwapInterval(1)
    Glfw3.glfwSwapBuffers(window)

  fun poll() =>
    Glfw3.glfwMakeContextCurrent(window)
    Glfw3.glfwPollEvents()

  fun draw(new_positions: Array[(F32, F32)] iso, old_positions: Array[(F32, F32)] iso) =>
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glUseProgram(program.handle)
    Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)

    Gl.glUniform3fv(Gl.glGetUniformLocation(program.handle, "color".cpointer()), 1, color_white.cpointer())
    Gl.glBufferData[(F32, F32)](GLArrayBuffer(), GLsizeiptr.from[USize]((32 / 8) * 2 * new_positions.size()), new_positions.cpointer(), GLDynamicDraw())
    Gl.glDrawArrays(GLPoints(), 0, GLsizei.from[USize](new_positions.size() * 2))

    Gl.glUniform3fv(Gl.glGetUniformLocation(program.handle, "color".cpointer()), 1, color_black.cpointer())
    Gl.glBufferData[(F32, F32)](GLArrayBuffer(), GLsizeiptr.from[USize]((32 / 8) * 2 * old_positions.size()), old_positions.cpointer(), GLDynamicDraw())
    Gl.glDrawArrays(GLPoints(), 0, GLsizei.from[USize](old_positions.size() * 2))

  fun ref resize(width: I32, height: I32) =>
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
      env.out.print("Error RD03, could not set projection matrix values")
    end
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glViewport(0, 0, width, height)
    Gl.glUseProgram(program.handle)
    Gl.glUniformMatrix4fv(Gl.glGetUniformLocation(program.handle, "projection".cpointer()), 1, GLFalse(), projection_matrix.cpointer())

  fun debug_message_callback(source: GLenum, type': GLenum, id: GLuint , severity: GLenum, length: GLsizei, message: Pointer[GLchar]) =>
    env.out.print("Error RD04, ...")
    // TODO implement...
