use "collections"

class Cluster
  let env: Env
  let grid: Grid ref
  let left: USize
  let top: USize
  let width: USize
  let height: USize

  var cells: Array[Cell]
  let cells_neighbour_indice: Array[Array[USize]]
  var dying_cells: Array[USize] = Array[USize]
  var reviving_cells: Array[USize] = Array[USize]
  var changed_cells: Set[USize] = Set[USize]

  new create(env': Env, grid': Grid ref, left': USize, top': USize, width': USize, height': USize) =>
    env = env'
    grid = grid'
    left = left'
    top = top'
    width = width'
    height = height'

    let total_cells: USize = width * height
    cells = Array[Cell](total_cells)
    cells_neighbour_indice = Array[Array[USize]](total_cells)
    while cells.size() < total_cells do
      cells_neighbour_indice.push(get_neighbour_cells_indice(cells.size()))
      cells.push(Cell)
    end

  fun ref spawn_cell_at_index(index: USize) =>
    revive_cell(index)

  fun ref revive_cell(index: USize) =>
    try
      cells(index)?.live()
      grid.add_position(get_global_cell_position(index))
    else
      env.out.print("Error CL03, could not find cell at index " + index.string())
    end
    try
      for neighbour_index in cells_neighbour_indice(index)?.values() do
        try
          cells(neighbour_index)?.add_neighbour()
          changed_cells.set(neighbour_index)
        else
          env.out.print("Error CL01, could not find cell at index " + neighbour_index.string())
        end
      end
    else
      env.out.print("Error CL03, could not find neighbours for cell at indice at index " + index.string())
    end

  fun ref kill_cell(index: USize) =>
    try
      cells(index)?.die()
      grid.remove_position(get_global_cell_position(index))
    else
      env.out.print("Error CL04, could not find cell at index " + index.string())
    end
    try
      for neighbour_index in cells_neighbour_indice(index)?.values() do
        try
          cells(neighbour_index)?.remove_neighbour()
          changed_cells.set(neighbour_index)
        else
          env.out.print("Error CL02, could not find cell at index " + neighbour_index.string())
        end
      end
    else
      env.out.print("Error CL03, could not find neighbours for cell at indice at index " + index.string())
    end

  fun ref update() =>
    for index in changed_cells.values() do
      try
        match cells(index)?.should_be()
        | DeadCell => dying_cells.push(index)
        | LivingCell => reviving_cells.push(index)
        end
      else
        env.out.print("Error CL05, could not find cell at index " + index.string())
      end
    end
    changed_cells.clear()
    for index in dying_cells.values() do
      kill_cell(index)
    end
    dying_cells.clear()
    for index in reviving_cells.values() do
      revive_cell(index)
    end
    reviving_cells.clear()

  fun get_cell_index(x: USize, y: USize): USize =>
    x + (y * width)

  fun get_cell_position(index: USize): (USize, USize) =>
    (index % width, index / width)

  fun get_neighbour_cells_indice(index: USize): Array[USize] =>
    let p = get_cell_position(index)
    recover
      let indices = Array[USize](8)
      if (p._1 > 0) then indices.push(get_cell_index(p._1 - 1, p._2)) end
      if (p._2 > 0) then indices.push(get_cell_index(p._1, p._2 - 1)) end
      if (p._1 < (width - 1)) then indices.push(get_cell_index(p._1 + 1, p._2)) end
      if (p._2 < (height - 1)) then indices.push(get_cell_index(p._1, p._2 + 1)) end
      if ((p._1 > 0) and (p._2 > 0)) then indices.push(get_cell_index(p._1 - 1, p._2 - 1)) end
      if ((p._1 < (width - 1)) and (p._2 < (height - 1))) then indices.push(get_cell_index(p._1 + 1, p._2 + 1)) end
      if ((p._1 > 0) and (p._2 < (height - 1))) then indices.push(get_cell_index(p._1 - 1, p._2 + 1)) end
      if ((p._1 < (width - 1)) and (p._2 > 0)) then indices.push(get_cell_index(p._1 + 1, p._2 - 1)) end
      indices
    end

  fun get_global_cell_position(index: USize): (USize, USize) =>
    let position = get_cell_position(index)
    (position._1 + left, position._2 + top)

