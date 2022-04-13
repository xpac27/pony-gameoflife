use "lib:opengl32" if windows
use "pony-glfw3/Glfw3"
use "pony-gl/Gl"
use "lib:GLEW" if linux

// TODO put in its own package
use @glewInit[GLenum]()

actor Main is GLFWWindowListener
  let env: Env
  let game: Game

  let window: NullablePointer[GLFWwindow]
  let window_user_object: GLFWWindowUserObject


  // TODO this goes in game
  var mouse_pressed: Bool = false

  new create(env': Env) =>
    // TODO this goes in the Window class
    let window_width: USize = 50
    let window_height: USize = 50

    env = env'

    if (Glfw3.glfwInit() == GLFWTrue()) then
      env.out.print("GLFW initialized version: " + Glfw3.glfwGetVersionString())

      // TODO wrap in a Window class
      Glfw3.glfwWindowHint(GLFWResizable(), GLFWFalse())
      Glfw3.glfwWindowHint(GLFWMaximized(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWDecorated(), GLFWFalse())
      Glfw3.glfwWindowHint(GLFWFocused(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWStencilBits(), 8)
      Glfw3.glfwWindowHint(GLFWDoublebuffer(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWContextVersionMajor(), 3)
      Glfw3.glfwWindowHint(GLFWContextVersionMinor(), 3)
      Glfw3.glfwWindowHint(GLFWOpenglForwardCompat(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWOpenglProfile(), GLFWOpenglCoreProfile())

      window = Glfw3.glfwCreateWindow(I32.from[USize](window_width), I32.from[USize](window_height), "Game of Life")

      Glfw3.glfwMakeContextCurrent(window)

      if (@glewInit() != 0) then
        env.out.print("Error, could not init glew")
      end

      // TODO set in the middle of the monitor
      Glfw3.glfwSetWindowPos(window, 400, 400)
    else
      // TODO better handle errors, the next steps wont work if we reach this scope
      env.out.print(Glfw3Helper.get_error_description())
      window = NullablePointer[GLFWwindow].none()
    end

    // TODO no need to pass window width/height if we have a nice window object that exposes it
    game = Game(env, window_width, window_height, window, GridUpdateToken(env.root))

    window_user_object = GLFWWindowUserObject(window)
    window_user_object.set_listener(this)
    window_user_object.enable_key_callback()
    window_user_object.enable_mouse_button_callback()
    window_user_object.enable_framebuffer_size_callback()
    window_user_object.enable_cursor_pos_callback()

  fun _final() =>
    Glfw3.glfwDestroyWindow(window)
    Glfw3.glfwTerminate()

  fun ref key_callback(key: I32 val, scancode: I32 val, action: I32 val, mods: I32 val) =>
    match key
    | GLFWKeyEscape()
    | GLFWKeyQ() => Glfw3.glfwSetWindowShouldClose(window, GLFWTrue())
    end
    // TODO send info to game

  fun ref framebuffer_size_callback(width: I32, height: I32) =>
    game.resize(USize.from[I32](width), USize.from[I32](height))

  fun ref mouse_button_callback(button: I32, action: I32, mods: I32) =>
    // TODO send info to game and pocess it there
    if (button == GLFWMouseButton1()) then
      if (action == GLFWPress()) then
        mouse_pressed = true
      elseif (action == GLFWRelease()) then
        mouse_pressed = false
      end
    end

  fun ref cursor_pos_callback(xpos': F64, ypos': F64) =>
    // TODO send info to game and pocess it there
    let xpos = F32.from[F64](xpos')
    let ypos = F32.from[F64](ypos')
    // TODO use the new method signature
    /* if (mouse_pressed) then */
    /*   grid.spawn_at_position((xpos, ypos)) */
    /*   grid.spawn_at_position((xpos, ypos)) */
    /*   grid.spawn_at_position((xpos + 1 , ypos)) */
    /*   grid.spawn_at_position((xpos, ypos + 1)) */
    /*   grid.spawn_at_position((xpos - 1 , ypos)) */
    /*   grid.spawn_at_position((xpos, ypos - 1)) */
    /*   grid.spawn_at_position((xpos + 2 , ypos)) */
    /*   grid.spawn_at_position((xpos, ypos + 2)) */
    /*   grid.spawn_at_position((xpos - 2 , ypos)) */
    /*   grid.spawn_at_position((xpos, ypos - 2)) */
    /* end */

