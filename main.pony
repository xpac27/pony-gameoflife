use "pony-glfw3/Glfw3"
use "pony-gl/Gl"

actor Main is WindowListener
  let env: Env
  let window: NullablePointer[GLFWwindow]
  var window_width: I32 = 640
  var window_height: I32 = 480
  let window_user_object: WindowUserObject
  var program: GLuint = GLNone()
  var vertex_array_objects: Array[GLuint] = Array[GLuint]

  new create(env': Env) =>
    env = env'

    if (Glfw3.glfwInit() == GLFWTrue()) then
      env.out.print("GLFW initialized version: " + Glfw3.glfwGetVersionString())

      Glfw3.glfwSwapInterval(1)

      Glfw3.glfwWindowHint(GLFWResizable(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWDecorated(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWFocused(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWDoublebuffer(), GLFWTrue())

      Glfw3.glfwWindowHint(GLFWContextVersionMajor(), 3)
      Glfw3.glfwWindowHint(GLFWContextVersionMinor(), 3)
      Glfw3.glfwWindowHint(GLFWOpenglForwardCompat(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWOpenglProfile(), GLFWOpenglCoreProfile())

      window = Glfw3.glfwCreateWindow(window_width, window_height, "My Title")
      Glfw3.glfwMakeContextCurrent(window)

      window_user_object = WindowUserObject(window)
      window_user_object.set_listener(this)
      window_user_object.enable_key_callback()

      env.out.print("GL version: " + GlHelper.glGetString(GLVersion()))

      let vertex_shader_source: String =
        """
        #version 330
        void main(void)
        {
          gl_Position = vec4(0.0, 0.0, 0.0, 1.0);
        }
        """

      let fragment_shader_source: String =
        """
        #version 330
        out vec4 color;
        void main(void)
        {
          color = vec4(0.0, 0.0, 1.0, 1.0);
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
      Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)

      loop()
    else
      env.out.print("Error: could not initialize GLFW")
      env.out.print(Glfw3Helper.get_error_description())
      window = NullablePointer[GLFWwindow].none()
      window_user_object = WindowUserObject.none()
    end

  be loop() =>
    if (Glfw3.glfwWindowShouldClose(window) == 0) then
      Glfw3.glfwPollEvents()

      (window_width, window_height) = Glfw3Helper.get_window_size(window)

      Gl.glViewport(0, 0, window_width, window_height)
      Gl.glClearColor(1.0, 1.0, 0.0, 1.0)
      Gl.glColorMask(GLTrue(), GLTrue(), GLTrue(), GLTrue())
      Gl.glClear(GLColorBufferBit())
      Gl.glColorMask(GLFalse(), GLFalse(), GLFalse(), GLFalse())
      Gl.glUseProgram(program)
      Gl.glDrawArrays(GLPoints(), 0, 1)

      Glfw3.glfwSwapBuffers(window)

      loop()
    else
      Glfw3.glfwDestroyWindow(window)
      Glfw3.glfwTerminate()
    end

  fun key_callback(key: I32 val, scancode: I32 val, action: I32 val, mods: I32 val) =>
    match key
    | GLFWKeyEscape()
    | GLFWKeyQ() => Glfw3.glfwSetWindowShouldClose(window, GLFWTrue())
    end
    env.out.print("key: " + key.string())

