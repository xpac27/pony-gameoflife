use "package:pony-glfw3/Glfw3"

class CustomCallbacks is Callbacks
  fun @keyCallback(window: NullablePointer[GLFWwindow] tag, key: I64 val, scancode: I64 val, action: I64 val, mods: I64 val) =>
    match key
    | GLFWkey.escape()
    | GLFWkey.letter_q() => Glfw3.glfwSetWindowShouldClose(window, 1)
    end
    try
      let data = Glfw3.glfwGetWindowUserPointer(window) as WindowUserNotify
      data.env.out.print("key: " + key.string())
    end

class WindowUserNotify is Notify
  let env: Env

  new create(env': Env) =>
    env = env'

actor Main
  let window: NullablePointer[GLFWwindow]
  let custom_callbacks: CustomCallbacks
  let window_user_notify: WindowUserNotify

  new create(env: Env) =>
    custom_callbacks = CustomCallbacks
    window_user_notify = WindowUserNotify(env)

    if (Glfw3.glfwInit() == 1) then env.out.print("WOOT") end

    window =
    Glfw3.glfwCreateWindow(640, 480, "My Title", NullablePointer[GLFWmonitor].none(), NullablePointer[GLFWwindow].none())
    Glfw3.glfwSetWindowUserPointer(window, env)
    Glfw3.glfwSetWindowUserPointer(window, window_user_notify)
    Glfw3.glfwSetKeyCallback(window, custom_callbacks)
    loop()

  be loop() =>
    if (Glfw3.glfwWindowShouldClose(window) == 0) then
      Glfw3.glfwPollEvents()
      loop()
    else
      Glfw3.glfwDestroyWindow(window)
      Glfw3.glfwTerminate()
    end

