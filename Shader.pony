use "pony-gl/Gl"
use "files"

primitive VertexShader
primitive GeometryShader
primitive FragmentShader
type ShaderType is (VertexShader | GeometryShader | FragmentShader)

class Shader
  let handle: GLuint

  new create(env: Env, shader_type: ShaderType, path: String) =>
    handle = match shader_type
    | VertexShader => Gl.glCreateShader(GLVertexShader())
    | GeometryShader => Gl.glCreateShader(GLGeometryShader())
    | FragmentShader => Gl.glCreateShader(GLFragmentShader())
    end
    try
      let file = File.open(FilePath(env.root as AmbientAuth, path)?)
      GlHelper.glShaderSource(handle, file.read_string(file.size()))
      Gl.glCompileShader(handle)
      if (GlHelper.glGetShaderiv(handle, GLCompileStatus()) == GLFalse()) then
        env.out.print(GlHelper.glGetShaderInfoLog(handle))
      end
    else
      env.out.print("Error, could not open " + path)
    end

  fun _final() =>
    Gl.glDeleteShader(handle)
