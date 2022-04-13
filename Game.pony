use "pony-glfw3/Glfw3"

// TODO make a game package
class Game
  let env: Env
  let renderer: Renderer
  let grid: Grid

  new create(env': Env, width: USize, height: USize, window: NullablePointer[GLFWwindow], token: GridUpdateToken iso) =>
    env = env'
    renderer = Renderer(env, window, width, height)
    grid = Grid(env, renderer, width, height)
    grid.>spawn_at_positions([
      (10, 10)
      (10, 11)
      (10, 12)
    ])
    .update(consume token)

  fun resize(width: USize, height: USize) =>
    grid.resize(width, height)
    renderer.resize(width, height)
