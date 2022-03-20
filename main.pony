use "pony-glfw3/Glfw3"
use "pony-gl/Gl"

actor Main is WindowListener
  let env: Env
  let glfw_window: GLFWWindow
  var glfw_window_width: I32 = 640
  var glfw_window_height: I32 = 480

  new create(env': Env) =>
    env = env'

    if (GLFW.init() == GLFWTrue()) then
      env.out.print("GLFW initialized version: " + GLFW.get_version_string())

      GLFW.swap_interval(1)

      GLFW.window_hint(GLFWResizable(), GLFWTrue())
      GLFW.window_hint(GLFWDecorated(), GLFWTrue())
      GLFW.window_hint(GLFWFocused(), GLFWTrue())
      GLFW.window_hint(GLFWDoublebuffer(), GLFWTrue())

      GLFW.window_hint(GLFWContextVersionMajor(), 3)
      GLFW.window_hint(GLFWContextVersionMinor(), 3)
      GLFW.window_hint(GLFWOpenglForwardCompat(), GLFWTrue())
      GLFW.window_hint(GLFWOpenglProfile(), GLFWOpenglCoreProfile())

      glfw_window = GLFWWindow(glfw_window_width, glfw_window_height, "Pony - Game of life")
      glfw_window.set_listener(this)
      glfw_window.enable_key_callback()
      glfw_window.make_context_current()

      env.out.print("GL version: " + GL.glGetString(GLVersion()))

      repeat
        (glfw_window_width, glfw_window_height) = glfw_window.get_size()

        GLFW.poll_events()

        GL.glViewport(0, 0, glfw_window_width, glfw_window_height)
        GL.glClearColor(1.0, 1.0, 0.0, 1.0)
        GL.glColorMask(GLTrue(), GLTrue(), GLTrue(), GLTrue())
        GL.glClear(GLColorBufferBit())
        GL.glColorMask(GLFalse(), GLFalse(), GLFalse(), GLFalse())

        glfw_window.swap_buffers()
      until
        glfw_window.should_close()
      end

      GLFW.terminate()
    else
      env.out.print("Error: could not initialize GLFW")
      env.out.print(GLFW.get_error()._2)
      glfw_window = GLFWWindow.none()
    end

  fun key_callback(key: I32 val, scancode: I32 val, action: I32 val, mods: I32 val) =>
    match key
    | GLFWKeyEscape()
    | GLFWKeyQ() => glfw_window.set_should_close(true)
    end
    env.out.print("key: " + key.string())

