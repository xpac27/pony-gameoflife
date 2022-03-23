#version 330
layout (location = 0) in vec3 aPos;
void main(void)
{
    gl_Position = vec4(aPos.x, aPos.y, 0.0f, 1.0f);
}

