use "pony-glfw3/Glfw3"
use "pony-gl/Gl"
use "files"
use "random"

actor Cell
  var alive: Bool = false
  var alive_neighbour: U8 = 0

  let index: I32
  let main: Main tag
  let env: Env
  let debug: Bool

  new create(main': Main, env': Env, index': I32, debug': Bool) =>
    main = main'
    env = env'
    index = index'
    debug = debug'

  /* let cells: Array[Cell tag] val */
  /* let index: USize */
  /* new create(cells: Array[Cell tag] val, index: USize) => */
  /*   cells = cells */
  /*   index = index */

  be live() =>
    if debug then env.out.print(index.string() + " is alive") end
    alive = true
    main.hello_neighbourgs(index)

  be die() =>
    if debug then env.out.print(index.string() + " is dead") end
    alive = false
    main.goodbye_neighbourgs(index)

  be neighbour_lives() =>
    if debug then env.out.print(index.string() + " gained neighbour") end
    alive_neighbour = alive_neighbour + 1
    main.cell_updated(index)

  be neighbour_dies() =>
    if debug then env.out.print(index.string() + " lost neighbour") end
    alive_neighbour = alive_neighbour - 1
    main.cell_updated(index)

  be compute() =>
    if (alive == true) and ((alive_neighbour < 2) or (alive_neighbour > 3)) then
      if debug then env.out.print(index.string() + " should die") end
      main.dies(index)
    elseif (alive == false) and (alive_neighbour == 3) then
      if debug then env.out.print(index.string() + " should live") end
      main.lives(index)
    end

actor Main is (GLFWWindowListener & GLDebugMessageListener)
  let env: Env
  let rand: Rand = Rand
  let window: NullablePointer[GLFWwindow]
  let window_user_object: GLFWWindowUserObject
  let vertex_buffer_objects: Array[GLuint] = Array[GLuint].init(-1, 1)
  let vertex_array_objects: Array[GLuint] = Array[GLuint].init(-1, 1)

  var program: GLuint = GLNone()
  var positions: Array[(F32 val, F32 val)] = Array[(F32 val, F32 val)]
  var projection_matrix: Array[F32] = Array[F32].init(0, 4 * 4)
  var cells: Array[Cell] = Array[Cell]
  var updating_cells: I32 = 0
  var iteration: I32 = 0
  var refreshed: Bool = true // should be called dirty and be the opposit

  let debug: Bool = false
  let grid_width: I32 = 100
  let grid_height: I32 = 100
  let indices: Array[I32] = [2050; 2051; 2052 ; 2150 ; 2250 ; 2251 ; 2252 ; 2352]

  new create(env': Env) =>
    env = env'

    if (Glfw3.glfwInit() == GLFWTrue()) then
      env.out.print("GLFW initialized version: " + Glfw3.glfwGetVersionString())

      Glfw3.glfwWindowHint(GLFWResizable(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWDecorated(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWFocused(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWDoublebuffer(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWContextVersionMajor(), 3)
      Glfw3.glfwWindowHint(GLFWContextVersionMinor(), 3)
      Glfw3.glfwWindowHint(GLFWOpenglForwardCompat(), GLFWTrue())
      Glfw3.glfwWindowHint(GLFWOpenglProfile(), GLFWOpenglCoreProfile())

      window = Glfw3.glfwCreateWindow(grid_width, grid_height, "Game of Life")
      window_user_object = GLFWWindowUserObject(window)
      window_user_object.set_listener(this)
      window_user_object.enable_key_callback()
      window_user_object.enable_framebuffer_size_callback()

      Glfw3.glfwMakeContextCurrent(window)
      Glfw3.glfwSwapInterval(1)

      Gl.glDebugMessageControl(GLDontCare(), GLDebugTypeOther(), GLDontCare())
      Gl.glEnable(GLDebugOutputSynchronous())
      Gl.glEnable(GLDebugOutput())

      env.out.print("GL version: " + GlHelper.glGetString(GLVersion()))

      let vertex_shader: GLuint = Gl.glCreateShader(GLVertexShader())
      load_shader(vertex_shader, "shaders/default.vert")

      let fragment_shader: GLuint = Gl.glCreateShader(GLFragmentShader())
      load_shader(fragment_shader, "shaders/default.frag")

      program = Gl.glCreateProgram()
      link_program(program, vertex_shader, fragment_shader)

      delete_shader(vertex_shader)
      delete_shader(fragment_shader)

      Gl.glGenVertexArrays(1, vertex_array_objects.cpointer())
      Gl.glGenBuffers(1, vertex_buffer_objects.cpointer())

      Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)
      Gl.glBindBuffer(GLArrayBuffer(), try vertex_buffer_objects(0)? else GLNone() end)

      Gl.glVertexAttribPointer(0, 2, GLFloatType(), GLFalse(), 2 * 4)
      Gl.glEnableVertexAttribArray(0)

      Gl.glBindVertexArray(GLNone())

      var i: I32 = 0
      let t: I32 = grid_width * grid_height
      while i < t do
        cells.push(Cell(this, env, i, debug))
        i = i + 1
      end

      for index in indices.values() do
        lives(index)
      end

      draw()
    else
      env.out.print(Glfw3Helper.get_error_description())
      window = NullablePointer[GLFWwindow].none()
      window_user_object = GLFWWindowUserObject.none()
    end

  be draw() =>
    if debug then env.out.print("draw") end
    Glfw3.glfwMakeContextCurrent(window)

    Gl.glClearColor(0.0, 0.0, 0.0, 1.0)
    Gl.glClear(GLColorBufferBit())
    Gl.glUseProgram(program)
    Gl.glUniformMatrix4fv(Gl.glGetUniformLocation(program, "projection".cpointer()), 1, GLFalse(), projection_matrix.cpointer())
    Gl.glBindVertexArray(try vertex_array_objects(0)? else GLNone() end)
    Gl.glBufferData[(F32, F32)](GLArrayBuffer(), GLsizeiptr.from[USize]((32 / 8) * 2 * positions.size()), positions.cpointer(), GLDynamicDraw())
    Gl.glDrawArrays(GLPoints(), 0, GLsizei.from[USize](positions.size() * 2))

    Glfw3.glfwSwapBuffers(window)
    Glfw3.glfwPollEvents()

    if (Glfw3.glfwWindowShouldClose(window) == GLFWTrue()) then return end

    draw()

    if (updating_cells == 0) then
      if ((refreshed = true) == false) then
        if debug then env.out.print("refresh") end
        if debug then env.out.print("iteration " + (iteration = iteration + 1).string()) end
        for cell in cells.values() do
          cell.compute()
        end
      end
    end

  fun _final() =>
    Gl.glDeleteProgram(program)
    Gl.glDeleteBuffers(1, vertex_buffer_objects.cpointer())
    Gl.glDeleteVertexArrays(1, vertex_array_objects.cpointer())

    Glfw3.glfwDestroyWindow(window)
    Glfw3.glfwTerminate()

  be lives(index: I32) =>
    if debug then env.out.print(index.string() + " borns at " + F32.from[I32](index % grid_width).string() + "." + F32.from[I32](index / grid_width).string()) end
    positions.push((F32.from[I32](index % grid_width), F32.from[I32](index / grid_width)))
    try
      cells(USize.from[I32](index))?.live()
    else
      env.out.print("Error, could not find cell at index " + index.string())
    end

  be dies(index: I32) =>
    if debug then env.out.print(index.string() + " dies at " + F32.from[I32](index % grid_width).string() + "." + F32.from[I32](index / grid_width).string()) end
    try
      let result: USize = positions.find((F32.from[I32](index % grid_width), F32.from[I32](index / grid_width)))?
      try
        positions.delete(result)?
      else
        env.out.print("Error, could not remove position from index " + index.string())
      end
    else
      env.out.print("Error, could not find position from index " + index.string())
    end
    try cells(USize.from[I32](index))?.die() end

  be hello_neighbourgs(index: I32) =>
    if debug then env.out.print(index.string() + " welcome its neighbours") end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - 1))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + 1))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - grid_width))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + grid_width))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - (grid_width - 1)))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - (grid_width + 1)))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + (grid_width - 1)))?.neighbour_lives() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + (grid_width + 1)))?.neighbour_lives() end
    refreshed = false

  be goodbye_neighbourgs(index: I32) =>
    if debug then env.out.print(index.string() + " goodbye its neighbours") end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - 1))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + 1))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - grid_width))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + grid_width))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - (grid_width - 1)))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index - (grid_width + 1)))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + (grid_width - 1)))?.neighbour_dies() end
    try updating_cells = updating_cells + 1 ; cells(USize.from[I32](index + (grid_width + 1)))?.neighbour_dies() end
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

  fun load_shader(shader: GLuint val, path: String) =>
    Glfw3.glfwMakeContextCurrent(window)
    try
      let file = File.open(FilePath(env.root as AmbientAuth, path)?)
      GlHelper.glShaderSource(shader, file.read_string(file.size()))
      Gl.glCompileShader(shader)
      if (GlHelper.glGetShaderiv(shader, GLCompileStatus()) == GLFalse()) then
        env.out.print(GlHelper.glGetShaderInfoLog(shader))
      end
    else
      env.out.print("Error, could not open " + path)
    end

  fun link_program(target: GLuint val, vertex_shader: GLuint val, fragment_shader: GLuint val) =>
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glAttachShader(target, vertex_shader)
    Gl.glAttachShader(target, fragment_shader)
    Gl.glLinkProgram(target)
    if (GlHelper.glGetProgramiv(target, GLLinkStatus()) == 0) then
      env.out.print(GlHelper.glGetProgramInfoLog(target))
    end

  fun delete_shader(shader: GLuint) =>
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glDeleteShader(shader)

  /* fun ref spawn_cells(total: I32) => */
  /*   var i: I32 = 0 */
  /*   while (i = i + 1) < total do */
  /*     /1* env.out.print(USize.from[F64](rand.real() * F64.from[USize](cells.size())).string()) *1/ */
  /*     /1* env.out.print(rand.usize().string()) *1/ */
  /*     let index = USize.from[F64](rand.real() * F64.from[USize](cells.size())) */
  /*     try */
  /*       env.out.print(index.string() + " is born") */
  /*       cells(index)?.live() */
  /*     else */
  /*       env.out.print("Error, cell index out of bound: " + index.string()) */
  /*     end */
  /*   end */

  fun ref key_callback(key: I32 val, scancode: I32 val, action: I32 val, mods: I32 val) =>
    match key
    | GLFWKeyEscape()
    | GLFWKeyQ() => Glfw3.glfwSetWindowShouldClose(window, GLFWTrue())
    end
    if debug then env.out.print("key: " + key.string()) end

  fun ref framebuffer_size_callback(width: I32, height: I32) =>
    let l: F32 = 0.0
    let r: F32 = F32.from[I32](width)
    let b: F32 = F32.from[I32](height)
    let t: F32 = 0.0
    let n: F32 = -1.0
    let f: F32 = 10.0
    try
      projection_matrix.update((0 * 4) + 0, 2.0 / (r - l))?
      projection_matrix.update((1 * 4) + 1, 2.0 / (t - b))?
      projection_matrix.update((2 * 4) + 2, -2.0 / (f - n))?
      projection_matrix.update((3 * 4) + 0, - (r + l) / (r - l))?
      projection_matrix.update((3 * 4) + 1, - (t + b) / (t - b))?
      projection_matrix.update((3 * 4) + 2, - (f + n) / (f - n))?
      projection_matrix.update((3 * 4) + 3, 1.0)?
    else
      env.out.print("Error, could not set projection matrix values")
    end
    Glfw3.glfwMakeContextCurrent(window)
    Gl.glViewport(0, 0, width, height)

  fun debug_message_callback(source: GLenum, type': GLenum, id: GLuint , severity: GLenum, length: GLsizei, message: Pointer[GLchar]) =>
    env.out.print("OpenGL Error...")

