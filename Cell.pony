actor Cell
  var alive: Bool = false
  var alive_neighbour: U8 = 0

  let index: I32
  let grid: Grid
  let env: Env
  let debug: Bool

  new create(grid': Grid, env': Env, index': I32, debug': Bool) =>
    grid = grid'
    env = env'
    index = index'
    debug = debug'

  be live() =>
    if debug then env.out.print(index.string() + " is alive") end
    alive = true
    grid.hello_neighbourgs(index)

  be die() =>
    if debug then env.out.print(index.string() + " is dead") end
    alive = false
    grid.goodbye_neighbourgs(index)

  be neighbour_lives() =>
    if debug then env.out.print(index.string() + " gained neighbour") end
    alive_neighbour = alive_neighbour + 1
    grid.cell_updated(index)

  be neighbour_dies() =>
    if debug then env.out.print(index.string() + " lost neighbour") end
    alive_neighbour = alive_neighbour - 1
    grid.cell_updated(index)

  be compute() =>
    if (alive == true) and ((alive_neighbour < 2) or (alive_neighbour > 3)) then
      if debug then env.out.print(index.string() + " should die") end
      grid.dies(index)
    elseif (alive == false) and (alive_neighbour == 3) then
      if debug then env.out.print(index.string() + " should live") end
      grid.lives(index)
    end
