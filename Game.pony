use "pony-glfw3/Glfw3"
use "random"
use "collections"
use "itertools"
use "time"

primitive GameOperations
  fun tag scale_usize(value: USize, factor: F32): USize =>
    USize.from[F32]((F32.from[USize](value) * factor))

// TODO make a game package
class Game
  let env: Env
  let renderer: Renderer
  let grid: Grid
  let scale: F32 = 0.4

  var mouse_position: Position = (0, 0)

  new create(env': Env, width': USize, height': USize, window: NullablePointer[GLFWwindow], token: GridUpdateToken iso) =>
    let width = GameOperations.scale_usize(width', scale)
    let height = GameOperations.scale_usize(height', scale)
    env = env'
    renderer = Renderer(env, window, width, height, (1.0 / scale))
    grid = Grid(env, renderer, width, height)
    grid.>spawn_at_positions([
      (10, 10)
      (10, 11)
      (10, 12)
    ])
    .update(consume token)

  fun resize(width': USize, height': USize) =>
    let width = GameOperations.scale_usize(width', scale)
    let height = GameOperations.scale_usize(height', scale)
    grid.resize(width, height)
    renderer.resize(width, height)

  fun ref left_mouse_button_released() =>
    grid.spawn_at_positions(recover val
      let rand: Rand = Rand.from_u64(Time.millis())
      let amount: USize = 32
      let spread: F64 = 16
      Iter[USize](Range(0, amount)).map_stateful[Position]({
        (i: USize) =>
          (
            mouse_position._1 + F32.from[F64]((rand.real() * spread) - (spread / 2.0)),
            mouse_position._2 + F32.from[F64]((rand.real() * spread) - (spread / 2.0))
          )
      })
      .collect(Array[Position](amount))
    end)
    // Alternative to spawn only 1 cell at a time
    // grid.spawn_at_positions([mouse_position])

  fun ref mouse_moved(x: F64, y: F64) =>
    mouse_position = (
      F32.from[F64](x) * scale,
      F32.from[F64](y) * scale
    )

