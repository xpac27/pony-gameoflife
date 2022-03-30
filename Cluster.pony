use "collections"

class Cluster
  let env: Env
  let grid: Grid ref
  let left: USize
  let top: USize
  let width: USize
  let height: USize

  var cells: Array[Cell]
  var neighbour_indice: Array[Array[USize]]

  var revived_cells: Array[USize] = Array[USize]
  var killed_cells: Array[USize] = Array[USize]

  new create(env': Env, grid': Grid ref, left': USize, top': USize, width': USize, height': USize) =>
    env = env'
    grid = grid'
    left = left'
    top = top'
    width = width'
    height = height'

    let total_cells: USize = width * height
    neighbour_indice = Array[Array[USize]](total_cells)
    cells = Array[Cell](total_cells)
    while cells.size() < total_cells do
      neighbour_indice.push(get_neighbour_cells_indice(cells.size()))
      cells.push(Cell)
    end

  fun ref spawn_cell_at_index(index: USize) =>
    try
      if (not cells(index)?.alive and not revived_cells.contains(index)) then
        revived_cells.push(index)
      end
    else
      env.out.print("Error CL00, could not find cell at index " + index.string())
    end

  fun ref update() =>
    var new_positions: Array[(F32, F32)] iso = recover Array[(F32, F32)] end
    var old_positions: Array[(F32, F32)] iso = recover Array[(F32, F32)] end
    new_positions.reserve(revived_cells.size())
    old_positions.reserve(killed_cells.size())

    for index in revived_cells.values() do
      try
        let cell = cells(index)?
        cell.alive = true
        new_positions.push(get_global_cell_position(index))
        try
          for neighbour_index in neighbour_indice(index)?.values() do
            try
              let neighbour = cells(neighbour_index)?
              neighbour.alive_neighbour = neighbour.alive_neighbour + 1
            else
              env.out.print("Error CL02, could not find cell at index " + neighbour_index.string())
            end
          end
        else
          env.out.print("Error CL02, could not find neighbour cell at indice at index " + index.string())
        end
      else
        env.out.print("Error CL01, could not find cell at index " + index.string())
      end
    end

    for index in killed_cells.values() do
      try
        let cell = cells(index)?
        cell.alive = false
        old_positions.push(get_global_cell_position(index))
        try
          for neighbour_index in neighbour_indice(index)?.values() do
            try
              let neighbour = cells(neighbour_index)?
              neighbour.alive_neighbour = neighbour.alive_neighbour - 1
            else
              env.out.print("Error CL02, could not find cell at index " + neighbour_index.string())
            end
          end
        else
          env.out.print("Error CL02, could not find neighbour cell at indice at index " + index.string())
        end
      else
        env.out.print("Error CL01, could not find cell at index " + index.string())
      end
    end

    revived_cells.clear()
    killed_cells.clear()

    var index: USize = 0
    while index < cells.size() do
      try
        match cells(index)?.should_be()
        | DeadCell => killed_cells.push(index)
        | LivingCell => revived_cells.push(index)
        end
      else
        env.out.print("Error CL07, could not find cell at index " + index.string())
      end
      index = index + 1
    end

    grid.report_positions(consume new_positions, consume old_positions)

  fun get_cell_index(x: USize, y: USize): USize =>
    x + (y * width)

  fun get_cell_position(index: USize): (USize, USize) =>
    (index % width, index / width)

  fun get_neighbour_cells_indice(index: USize): Array[USize] =>
    let p = get_cell_position(index)
    recover
      let indices = Array[USize](8)
      let x = p._1
      let y = p._2
      let w = I32.from[USize](width)
      if (x > 0) then indices.push(get_cell_index(x - 1, y)) end
      if (y > 0) then indices.push(get_cell_index(x, y - 1)) end
      if (x < (width - 1)) then indices.push(get_cell_index(x + 1, y)) end
      if (y < (height - 1)) then indices.push(get_cell_index(x, y + 1)) end
      if ((x > 0) and (y < (height - 1))) then indices.push(get_cell_index(x - 1, y + 1)) end
      if ((x < (width - 1)) and (y > 0)) then indices.push(get_cell_index(x + 1, y - 1)) end
      if ((x > 0) and (y > 0)) then indices.push(get_cell_index(x - 1, y - 1)) end
      if ((x < (width - 1)) and (y < (height - 1))) then indices.push(get_cell_index(x + 1, y + 1)) end
      indices
    end

  fun get_global_cell_position(index: USize): (F32, F32) =>
    let position = get_cell_position(index)
    (F32.from[USize](position._1 + left), F32.from[USize](position._2 + top))

