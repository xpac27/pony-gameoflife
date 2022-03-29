use "pony-gl/Gl"

class Program
  let handle: GLuint

  new create(env: Env, shaders: Array[Shader]) =>
    handle = Gl.glCreateProgram()
    for shader in shaders.values() do
      Gl.glAttachShader(handle, shader.handle)
    end
    Gl.glLinkProgram(handle)
    if (GlHelper.glGetProgramiv(handle, GLLinkStatus()) == 0) then
      env.out.print(GlHelper.glGetProgramInfoLog(handle))
    end

  fun _final() =>
    Gl.glDeleteProgram(handle)
