use "collections"
use "itertools"
use "promises"

// TODO split into files
// TODO use one more type for width/height
type Index is USize

interface GridPositionAccessor
  be access(fn: {(GridPositionAccessor ref)} val)
  fun box get_old_positions(): Array[Position] box
  fun box get_new_positions(): Array[Position] box

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

  // TODO use a map of prebuilt promise instead of creating new ones
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

actor Grid
  let _env: Env
  let _renderer: Renderer

  var _width: USize
  var _height: USize
  var _cells: Array[Cell tag] val = recover _cells.create() end
  var _cells_neighbours: Array[Array[Cell tag] val] val = recover _cells_neighbours.create() end
  var _spawn_requests: Array[Index] = _spawn_requests.create()
  var _dirty_cells: Array[Cell tag] = _dirty_cells.create()
  var _old_positions: Array[Position] = _old_positions.create()
  var _new_positions: Array[Position] = _new_positions.create()

  new create(env: Env, renderer: Renderer, width: USize, height: USize) =>
    _env = env
    _renderer = renderer
    _width = width
    _height = height
    _apply_size()

  be resize(width': USize, height': USize) =>
    _width = width'
    _height = height'
    _apply_size()

  fun ref _apply_size() =>
    _reset_cells()
    _reset_neighbours()

  be update(token: GridUpdateToken iso) =>
    _update_recurively()

  be _update_recurively() =>
    let spawn_promises = Iter[Index](_spawn_requests.values())
      .filter_map[Cell tag](GridOperations~index_to_cell(where lookup = _cells))
      .map[UpdateStateResultPromise](GridOperations~create_cell_spawn_promise())

    let cell_update_promises = Iter[Cell tag](_dirty_cells.values())
      .map[UpdateStateResultPromise](GridOperations~create_cell_update_promise())

    let all_promises = Iter[UpdateStateResultPromise].chain([spawn_promises; cell_update_promises].values())

    Promises[(UpdateStateResult)]
      .join(all_promises)
      .next[None](recover this~_receive_cell_update_state_results() end)

    _spawn_requests.clear()

  be _receive_cell_update_state_results(results: Array[(UpdateStateResult)] val) =>
    let alive_cells_neighbours = Iter[UpdateStateResult](results.values())
      .filter(GridOperations~filter_update_state(where expected = Alive))
      .map[Index](GridOperations~update_state_result_to_index())
      .flat_map[Cell tag](GridOperations~index_to_neighbours(where lookup = _cells_neighbours))
      .map[Cell tag](GridOperations~increment_cell_neighbour())

    let dead_cells_neighbours = Iter[UpdateStateResult](results.values())
      .filter(GridOperations~filter_update_state(where expected = Dead))
      .map[Index](GridOperations~update_state_result_to_index())
      .flat_map[Cell tag](GridOperations~index_to_neighbours(where lookup = _cells_neighbours))
      .map[Cell tag](GridOperations~decrement_cell_neighbour())

    Iter[Cell tag].chain([alive_cells_neighbours; dead_cells_neighbours].values())
      .unique[HashIs[Cell]]()
      .collect(_dirty_cells.>clear())

    Iter[UpdateStateResult](results.values())
      .filter(GridOperations~filter_update_state(where expected = Alive))
      .map[Index](GridOperations~update_state_result_to_index())
      .map[Position](GridOperations~index_to_position(where width = _width))
      .collect(_new_positions.>clear())

    Iter[UpdateStateResult](results.values())
      .filter(GridOperations~filter_update_state(where expected = Dead))
      .map[Index](GridOperations~update_state_result_to_index())
      .map[Position](GridOperations~index_to_position(where width = _width))
      .collect(_old_positions.>clear())

    _renderer.draw(this, recover this~_update_recurively() end)

  be spawn_at_positions(positions: Array[Position] val) =>
    Iter[Position](positions.values())
      .filter(GridOperations~validate_position(where width = _width, height = _height))
      .map[Index](GridOperations~position_to_index(where width = _width))
      .collect(_spawn_requests.>clear())

  be access(fn: {(GridPositionAccessor ref)} val) =>
    fn(this)

  fun box get_old_positions(): Array[Position] box =>
    _old_positions

  fun box get_new_positions(): Array[Position] box =>
    _new_positions

  fun _get_index(position: Position): USize =>
    USize.from[F32](position._1) + (USize.from[F32](position._2) * _width)

  fun ref _reset_cells() =>
    // TODO use iterators?
    _cells = recover
      let total = _width * _height
      var out: Array[Cell tag] iso = recover _cells.create(total) end
      for index in Range(0, total) do
        out.push(Cell(_env, index))
      end
      consume out
    end

  fun ref _reset_neighbours() =>
    // TODO use iterators?
    _cells_neighbours = recover
      var out: Array[Array[Cell tag] val] iso = recover _cells_neighbours.create(_cells.size()) end
      for index in Range(0, _cells.size()) do
        var neighbours: Array[Cell tag] iso = recover Array[Cell tag](8) end
        (let x, let y) = GridOperations.index_to_position(index, _width)
        let w = PositionType.from[USize](_width)
        let h = PositionType.from[USize](_height)
        if (x > 0) then try neighbours.push(_cells(_get_index((x - 1, y)))?) end end
        if (y > 0) then try neighbours.push(_cells(_get_index((x, y - 1)))?) end end
        if (x < (w - 1)) then try neighbours.push(_cells(_get_index((x + 1, y)))?) end end
        if (y < (h - 1)) then try neighbours.push(_cells(_get_index((x, y + 1)))?) end end
        if ((x > 0) and (y < (h - 1))) then try neighbours.push(_cells(_get_index((x - 1, y + 1)))?) end end
        if ((x < (w - 1)) and (y > 0)) then try neighbours.push(_cells(_get_index((x + 1, y - 1)))?) end end
        if ((x > 0) and (y > 0)) then try neighbours.push(_cells(_get_index((x - 1, y - 1)))?) end end
        if ((x < (w - 1)) and (y < (h - 1))) then try neighbours.push(_cells(_get_index((x + 1, y + 1)))?) end end
        out.push(consume neighbours)
      end
      consume out
    end

