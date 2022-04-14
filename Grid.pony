use "collections"
use "itertools"
use "promises"

// TODO split into files
// TODO use one more type for width/height
type Index is USize

primitive GridOperations
  fun tag validate_position(position: Position, width: USize, height: USize): Bool =>
    let x = USize.from[PositionType](position._1)
    let y = USize.from[PositionType](position._2)
    (x >= 0) and (y >= 0) and (x < width) and (y < height)

  fun tag position_to_index(position: Position, width: USize): Index =>
    let x = USize.from[PositionType](position._1)
    let y = USize.from[PositionType](position._2)
    x + (y * width)

  fun tag index_to_position(index: USize, width: USize): Position =>
    (PositionType.from[USize](index % width), PositionType.from[USize](index / width))

  fun tag index_to_cell(index: Index, lookup: Array[Cell tag] val): (Cell tag | None) =>
    try lookup(index)? else None end

  fun tag index_to_neighbours(index: Index, lookup: Array[Array[Cell tag] val] val): Iterator[Cell tag] =>
    try lookup(index)?.values() else Array[Cell tag].values() end

  fun tag increment_cell_neighbour(cell: Cell tag): Cell tag =>
    cell.>increment_alive_neighbour_count()

  fun tag decrement_cell_neighbour(cell: Cell tag): Cell tag =>
    cell.>decrement_alive_neighbour_count()

  fun tag create_cell_update_promise(cell: Cell tag): UpdateStateResultPromise =>
    let promise = UpdateStateResultPromise
    cell.update_state(promise)
    promise

  fun tag create_cell_spawn_promise(cell: Cell tag): UpdateStateResultPromise =>
    let promise = UpdateStateResultPromise
    cell.spawn(promise)
    promise

  fun tag filter_update_state(result: UpdateStateResult, expected: State): Bool =>
    result._1 is expected

  fun tag update_state_result_to_index(result: UpdateStateResult): Index =>
    result._2

class GridUpdateToken
    new iso create(auth: AmbientAuth) => None

class GridUpdater
  let grid: Grid

  var data: Array[Cell tag] iso

  new create(grid': Grid, data': Array[Cell tag] iso) =>
    grid = grid'
    data = consume data'

  fun ref apply() =>
    grid._update_recurively(data = recover data.create() end)

actor Grid
  let env: Env
  let renderer: Renderer

  var width: USize
  var height: USize
  var cells: Array[Cell tag] val = recover cells.create() end
  var cells_neighbours: Array[Array[Cell tag] val] val = recover cells_neighbours.create() end
  var spawn_requests: Array[Index] = spawn_requests.create()

  new create(env': Env, renderer': Renderer, width': USize, height': USize) =>
    env = env'
    renderer = renderer'
    width = width'
    height = height'
    apply_size()

  be resize(width': USize, height': USize) =>
    width = width'
    height = height'
    apply_size()

  fun ref apply_size() =>
    reset_cells()
    reset_neighbours()

  be update(token: GridUpdateToken iso) =>
    _update_recurively(recover Array[Cell tag] end)

  be _update_recurively(input_cells: Array[Cell tag] iso) =>
    let spawn_promises = Iter[Index](spawn_requests.values())
      .filter_map[Cell tag](GridOperations~index_to_cell(where lookup = cells))
      .map[UpdateStateResultPromise](GridOperations~create_cell_spawn_promise())

    let cell_update_promises = Iter[Cell tag]((consume input_cells).values())
      .map[UpdateStateResultPromise](GridOperations~create_cell_update_promise())

    let all_promises = Iter[UpdateStateResultPromise].chain([spawn_promises; cell_update_promises].values())

    Promises[(UpdateStateResult)]
      .join(all_promises)
      .next[None](recover this~_receive_cell_update_state_results() end)

    spawn_requests.clear()

  be _receive_cell_update_state_results(results: Array[(UpdateStateResult)] val) =>
    let dirty_cells = recover iso
      let alive_cells_neighbours = Iter[UpdateStateResult](results.values())
        .filter(GridOperations~filter_update_state(where expected = Alive))
        .map[Index](GridOperations~update_state_result_to_index())
        .flat_map[Cell tag](GridOperations~index_to_neighbours(where lookup = cells_neighbours))
        .map[Cell tag](GridOperations~increment_cell_neighbour())

      let dead_cells_neighbours = Iter[UpdateStateResult](results.values())
        .filter(GridOperations~filter_update_state(where expected = Dead))
        .map[Index](GridOperations~update_state_result_to_index())
        .flat_map[Cell tag](GridOperations~index_to_neighbours(where lookup = cells_neighbours))
        .map[Cell tag](GridOperations~decrement_cell_neighbour())

      Iter[Cell tag].chain([alive_cells_neighbours; dead_cells_neighbours].values())
        .unique[HashIs[Cell]]()
        .collect(Array[Cell tag])
    end

    let new_positions = recover val
      Iter[UpdateStateResult](results.values())
        .filter(GridOperations~filter_update_state(where expected = Alive))
        .map[Index](GridOperations~update_state_result_to_index())
        .map[Position](GridOperations~index_to_position(where width = width))
        .collect(Array[Position])
    end

    let old_positions = recover val
      Iter[UpdateStateResult](results.values())
        .filter(GridOperations~filter_update_state(where expected = Dead))
        .map[Index](GridOperations~update_state_result_to_index())
        .map[Position](GridOperations~index_to_position(where width = width))
        .collect(Array[Position])
    end

    renderer.draw(new_positions, old_positions, recover GridUpdater(this, consume dirty_cells) end)

  be spawn_at_positions(positions: Array[Position] val) =>
    spawn_requests =
      Iter[Position](positions.values())
        .filter(GridOperations~validate_position(where width = width, height = height))
        .map[Index](GridOperations~position_to_index(where width = width))
        .collect(Array[Index](positions.size()))

  fun get_index(position: Position): USize =>
    USize.from[F32](position._1) + (USize.from[F32](position._2) * width)

  fun ref reset_cells() =>
    // TODO use iterators?
    cells = recover
      let total = width * height
      var out: Array[Cell tag] iso = recover cells.create(total) end
      for index in Range(0, total) do
        out.push(Cell(env, index))
      end
      consume out
    end

  fun ref reset_neighbours() =>
    // TODO use iterators?
    cells_neighbours = recover
      var out: Array[Array[Cell tag] val] iso = recover cells_neighbours.create(cells.size()) end
      for index in Range(0, cells.size()) do
        var neighbours: Array[Cell tag] iso = recover Array[Cell tag](8) end
        (let x, let y) = GridOperations.index_to_position(index, width)
        let w = PositionType.from[USize](width)
        let h = PositionType.from[USize](height)
        if (x > 0) then try neighbours.push(cells(get_index((x - 1, y)))?) end end
        if (y > 0) then try neighbours.push(cells(get_index((x, y - 1)))?) end end
        if (x < (w - 1)) then try neighbours.push(cells(get_index((x + 1, y)))?) end end
        if (y < (h - 1)) then try neighbours.push(cells(get_index((x, y + 1)))?) end end
        if ((x > 0) and (y < (h - 1))) then try neighbours.push(cells(get_index((x - 1, y + 1)))?) end end
        if ((x < (w - 1)) and (y > 0)) then try neighbours.push(cells(get_index((x + 1, y - 1)))?) end end
        if ((x > 0) and (y > 0)) then try neighbours.push(cells(get_index((x - 1, y - 1)))?) end end
        if ((x < (w - 1)) and (y < (h - 1))) then try neighbours.push(cells(get_index((x + 1, y + 1)))?) end end
        out.push(consume neighbours)
      end
      consume out
    end

