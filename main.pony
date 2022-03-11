use "pony-glfw3/Glfw3"

actor Main is WindowCallbackListener
  let _window: NullablePointer[GLFWwindow]
  let _env: Env

  new create(env: Env) =>
    _env = env

    if (Glfw3.glfwInit() == 1) then _env.out.print("WOOT") end

    _window =
    Glfw3.glfwCreateWindow(640, 480, "My Title", NullablePointer[GLFWmonitor].none(), NullablePointer[GLFWwindow].none(), this)
    Glfw3.glfwEnableKeyCallback(_window)
    loop()

  be loop() =>
    if (Glfw3.glfwWindowShouldClose(_window) == 0) then
      Glfw3.glfwPollEvents()
      loop()
    else
      Glfw3.glfwDestroyWindow(_window)
      Glfw3.glfwTerminate()
    end

  fun keyCallback(window: NullablePointer[GLFWwindow] tag, key: I64 val, scancode: I64 val, action: I64 val, mods: I64 val) =>
    match key
    | GLFWkey.escape()
    | GLFWkey.letter_q() => Glfw3.glfwSetWindowShouldClose(window, 1)
    end
    _env.out.print("key: " + key.string())
