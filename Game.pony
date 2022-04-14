use "pony-glfw3/Glfw3"
use "random"
use "collections"
use "itertools"
use "time"

// TODO make a game package
class Game
  let env: Env
  let renderer: Renderer
  let grid: Grid

  var is_left_mouse_button_pressed: Bool = false

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

  fun ref left_mouse_button_pressed() =>
    is_left_mouse_button_pressed = true

  fun ref left_mouse_button_released() =>
    is_left_mouse_button_pressed = false

  fun ref mouse_moved(x: F64, y: F64) =>
    if is_left_mouse_button_pressed then
      grid.>spawn_at_positions(recover val
        let rand: Rand = Rand.from_u64(Time.millis())
        Iter[USize](Range(0, 10)).map_stateful[Position]({(i: USize) => (F32.from[F64](x + ((rand.real() * 10) - 5)), F32.from[F64](y + ((rand.real() * 10) - 5))) })
        .collect(Array[Position](10))
      end)
    end

