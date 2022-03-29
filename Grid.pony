use "pony-glfw3/Glfw3"

actor Grid
  let env: Env
  let renderer: Renderer
  let cluster_width: USize = 500
  let cluster_height: USize = 500
  let window: NullablePointer[GLFWwindow] tag // TODO should not be required

  var clusters: Array[Cluster] = Array[Cluster]
  var width: USize = 0
  var height: USize = 0
  var positions: Array[(F32, F32)] = Array[(F32, F32)]

  new create(env': Env, window': NullablePointer[GLFWwindow] tag) =>
    env = env'
    window = window'
    renderer = Renderer(env, window)

  be resize(width': I32, height': I32) =>
    width = USize.from[I32](width')
    height = USize.from[I32](height')
    renderer.resize(width', height')

    let rows = height / cluster_height
    let columns = width / cluster_width
    let total_culsters = columns * rows
    clusters.>clear().reserve(total_culsters)
    while clusters.size() < total_culsters do
      let cluster_x = (clusters.size() % columns) * cluster_width
      let cluster_y = (clusters.size() / columns) * cluster_height
      clusters.push(Cluster(env, this, cluster_x, cluster_y, cluster_width, cluster_height))
    end

  be update() =>
    for cluster in clusters.values() do
      cluster.update()
    end
    if (Glfw3.glfwWindowShouldClose(window) == GLFWFalse()) then
      update()
    end
    renderer.draw(positions)

  be spawn_at_position(position: (USize, USize)) =>
    spawn_at_index(get_index(position))

  be spawn_at_index(index: USize) =>
    if (index < (clusters.size() * (cluster_width * cluster_height))) then
      let cluster_index: USize = index / (cluster_width * cluster_height)
      let cluster_cell_local_index: USize = index % (cluster_width * cluster_height)
      try
        clusters(cluster_index)?.spawn_cell_at_index(cluster_cell_local_index)
      else
        env.out.print("Error GR01, could not find cluster at index " + cluster_index.string() + " from index " + index.string())
      end
    else
      env.out.print("Error GR02, out of bounds (" + (clusters.size() * (cluster_width * cluster_height)).string() + ") index " + index.string())
    end

  fun ref add_position(position: (USize, USize)) =>
    positions.push((F32.from[USize](position._1), F32.from[USize](position._2)))

  fun ref remove_position(position: (USize, USize)) =>
    try
      let result: USize = positions.find((F32.from[USize](position._1), F32.from[USize](position._2)))?
      try
        positions.delete(result)?
      else
        env.out.print("Error RD03, could not remove position " + position._1.string() + "x" + position._2.string())
      end
    else
      env.out.print("Error RD04, could not find position " + position._1.string() + "x" + position._2.string())
    end

  fun get_index(position: (USize, USize)): USize =>
    position._1 + (position._2 * width)

