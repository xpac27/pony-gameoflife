use "pony-glfw3/Glfw3"
use "pony-gl/Gl"

actor Main is GLFWWindowListener
  let env: Env
  let grid: Grid

  let window: NullablePointer[GLFWwindow]
  let window_user_object: GLFWWindowUserObject
  let window_width: I32 = 500
  let window_height: I32 = 500

  var mouse_pressed: Bool = false

  new create(env': Env) =>
    env = env'

    if (Glfw3.glfwInit() == GLFWTrue()) then
      env.out.print("GLFW initialized version: " + Glfw3.glfwGetVersionString())

      // TODO wrap in a Window class
      Glfw3.glfwWindowHint(GLFWResizable(), GLFWFalse())
      Glfw3.glfwWindowHint(GLFWMaximized(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWDecorated(), GLFWFalse())
      Glfw3.glfwWindowHint(GLFWFocused(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWDoublebuffer(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWContextVersionMajor(), 3)
      Glfw3.glfwWindowHint(GLFWContextVersionMinor(), 3)
      Glfw3.glfwWindowHint(GLFWOpenglForwardCompat(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWOpenglProfile(), GLFWOpenglCoreProfile())

      window = Glfw3.glfwCreateWindow(window_width, window_height, "Game of Life")

      // TODO set in the middle of the monitor
      Glfw3.glfwSetWindowPos(window, 400, 400)
    else
      env.out.print(Glfw3Helper.get_error_description())
      window = NullablePointer[GLFWwindow].none()
    end

    grid = Grid(env, window)
    grid.resize(window_width, window_height)

    window_user_object = GLFWWindowUserObject(window)
    window_user_object.set_listener(this)
    window_user_object.enable_key_callback()
    window_user_object.enable_mouse_button_callback()
    window_user_object.enable_framebuffer_size_callback()
    window_user_object.enable_cursor_pos_callback()

    let positions: Array[(F32, F32)] = [
      (10, 10)
      (10, 11)
      (10, 12)
    ]
    for position in positions.values() do
      grid.spawn_at_position(position)
    end

    grid.update()

  fun _final() =>
    Glfw3.glfwDestroyWindow(window)
    Glfw3.glfwTerminate()

  fun ref key_callback(key: I32 val, scancode: I32 val, action: I32 val, mods: I32 val) =>
    match key
    | GLFWKeyEscape()
    | GLFWKeyQ() => Glfw3.glfwSetWindowShouldClose(window, GLFWTrue())
    end

  fun ref framebuffer_size_callback(width: I32, height: I32) =>
    grid.resize(window_width, window_height)

  fun ref mouse_button_callback(button: I32, action: I32, mods: I32) =>
    if (button == GLFWMouseButton1()) then
      if (action == GLFWPress()) then
        mouse_pressed = true
      elseif (action == GLFWRelease()) then
        mouse_pressed = false
      end
    end

  fun ref cursor_pos_callback(xpos': F64, ypos': F64) =>
    let xpos = F32.from[F64](xpos')
    let ypos = F32.from[F64](ypos')
    if (mouse_pressed) then
      grid.spawn_at_position((xpos, ypos))
      grid.spawn_at_position((xpos, ypos))
      grid.spawn_at_position((xpos + 1 , ypos))
      grid.spawn_at_position((xpos, ypos + 1))
      grid.spawn_at_position((xpos - 1 , ypos))
      grid.spawn_at_position((xpos, ypos - 1))
      grid.spawn_at_position((xpos + 2 , ypos))
      grid.spawn_at_position((xpos, ypos + 2))
      grid.spawn_at_position((xpos - 2 , ypos))
      grid.spawn_at_position((xpos, ypos - 2))
    end

