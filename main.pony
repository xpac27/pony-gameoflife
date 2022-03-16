use "pony-glfw3/Glfw3"
use "pony-gl/Gl"

actor Main is WindowListener
  let env: Env
  let glfw_window: GLFWWindow
  var glfw_window_width: I32 = 640
  var glfw_window_height: I32 = 480

  new create(env': Env) =>
    env = env'

    if (GLFW.glfwInit() == 1) then env.out.print("WOOT") end

    glfw_window = GLFWWindow(glfw_window_width, glfw_window_height, "Pony - Game of life")
    glfw_window.set_listener(this)
    glfw_window.enable_key_callback()
    glfw_window.make_context_current()

    loop()

  be loop() =>
    if (glfw_window.should_close()) then
      GLFW.glfwTerminate()
    else
      (glfw_window_width, glfw_window_height) = glfw_window.get_size()
      env.out.print("glfw_window_width: " + glfw_window_width.string() + ", glfw_window_height: " + glfw_window_height.string())

      GLFW.glfwPollEvents()

      GL.glViewport(0, 0, glfw_window_width, glfw_window_height)
      GL.glClearColor(GLZero(), GLZero(), GLZero(), GLOne())
      GL.glColorMask(GLOne(), GLOne(), GLOne(), GLOne())
      GL.glClear(GLColorBufferBit())
      GL.glColorMask(GLZero(), GLZero(), GLZero(), GLZero())

      glfw_window.swap_buffers()

      loop()
    end

  fun key_callback(key: I64 val, scancode: I64 val, action: I64 val, mods: I64 val) =>
    match key
    | GLFW.key_escape()
    | GLFW.key_q() => glfw_window.set_should_close(true)
    end
    env.out.print("key: " + key.string())
