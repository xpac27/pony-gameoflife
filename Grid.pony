actor Grid
  let env: Env
  let main: Main
  let debug: Bool
  let width: I32 = 100
  let height: I32 = 100

  var cells: Array[Cell] = Array[Cell]
  var updating_cells: I32 = 0
  var iteration: I32 = 0
  var refreshed: Bool = true // should be called dirty and be the opposit

  new create(debug': Bool, env': Env, main': Main) =>
    debug = debug'
    env = env'
    main = main'

    var i: I32 = 0
    let t: I32 = width * height
    while i < t do
      cells.push(Cell(this, env, i, debug))
      i = i + 1
    end

  be spawn_at(x: I32, y: I32) =>
    if ((x >= 0) and (x < width) and (y >= 0) and (y < height)) then
      lives(x + (y * width))
    end

  be update() =>
    if (updating_cells == 0) then
      if ((refreshed = true) == false) then
        if debug then env.out.print("refresh") end
        if debug then env.out.print("iteration " + (iteration = iteration + 1).string()) end
        for cell in cells.values() do
          cell.compute()
        end
      end
    end

  be lives(index: I32) =>
    if debug then env.out.print(index.string() + " borns at " + F32.from[I32](index % width).string() + "." + F32.from[I32](index / width).string()) end
    main.add_position(F32.from[I32](index % width), F32.from[I32](index / width))
    try
      cells(USize.from[I32](index))?.live()
    else
      env.out.print("Error, could not find cell at index " + index.string())
    end

  be dies(index: I32) =>
    if debug then env.out.print(index.string() + " dies at " + F32.from[I32](index % width).string() + "." + F32.from[I32](index / width).string()) end
    main.remove_position(F32.from[I32](index % width), F32.from[I32](index / width))
    try cells(USize.from[I32](index))?.die() end

  be hello_neighbourgs(index: I32) =>
    if debug then env.out.print(index.string() + " welcome its neighbours") end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - 1))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + 1))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - width))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + width))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - (width - 1)))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - (width + 1)))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + (width - 1)))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + (width + 1)))?.neighbour_lives() end
    refreshed = false

  be goodbye_neighbourgs(index: I32) =>
    if debug then env.out.print(index.string() + " goodbye its neighbours") end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - 1))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + 1))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - width))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + width))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - (width - 1)))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - (width + 1)))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + (width - 1)))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + (width + 1)))?.neighbour_dies() end
    refreshed = false

  be cell_updated(index: I32) =>
    if debug then env.out.print("cell updated") end
    updating_cells = updating_cells - 1
    /* if (updating_cells == 0) then */
    /*   env.out.print("refresh") */
    /*   if ((refreshed = true) == false) then */
    /*     for cell in cells.values() do */
    /*       cell.compute() */
    /*     end */
    /*   end */
    /* end */

