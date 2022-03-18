use "pony-glfw3/Glfw3"
use "pony-gl/Gl"

actor Main is WindowListener
  let env: Env
  let glfw_window: GLFWWindow
  var glfw_window_width: I32 = 640
  var glfw_window_height: I32 = 480

  new create(env': Env) =>
    env = env'

    if (GLFW.init() == 1) then
      glfw_window = GLFWWindow(glfw_window_width, glfw_window_height, "Pony - Game of life")
      glfw_window.set_listener(this)
      glfw_window.enable_key_callback()
      glfw_window.make_context_current()

      loop()
    else
      env.out.print("Error: could not initialize GLFW")
      glfw_window = GLFWWindow.none()
    end

  be loop() =>
    if (glfw_window.should_close()) then
      GLFW.terminate()
    else
      (glfw_window_width, glfw_window_height) = glfw_window.get_size()

      GLFW.poll_events()

      GL.viewport(0, 0, glfw_window_width, glfw_window_height)
      GL.clear_color(GLZero(), GLZero(), GLZero(), GLOne())
      GL.color_mask(GLOne(), GLOne(), GLOne(), GLOne())
      GL.clear(GLColorBufferBit())
      GL.color_mask(GLZero(), GLZero(), GLZero(), GLZero())

      glfw_window.swap_buffers()

      loop()
    end

  fun key_callback(key: I32 val, scancode: I32 val, action: I32 val, mods: I32 val) =>
    match key
    | GLFWKeyEscape()
    | GLFWKeyQ() => glfw_window.set_should_close(true)
    end
    env.out.print("key: " + key.string())
