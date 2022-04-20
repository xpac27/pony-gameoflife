use "../pony-gl/Gl"
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
    let file_path = FilePath(FileAuth(env.root), path)
    let file = File.open(file_path)
    if file.errno() is FileOK then
      let data = file.read_string(file.size())
      GlHelper.glShaderSource(handle, consume data)
      Gl.glCompileShader(handle)
      if (GlHelper.glGetShaderiv(handle, GLCompileStatus()) == GLFalse()) then
        env.out.print(GlHelper.glGetShaderInfoLog(handle))
      end
    else
      env.out.print("Error, could not open " + path)
    end

  fun _final() =>
    Gl.glDeleteShader(handle)
