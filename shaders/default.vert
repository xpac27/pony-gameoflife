#version 330
layout (location = 0) in vec3 aPos;

uniform mat4 projection;

void main(void)
{
    gl_Position = projection * vec4(aPos.x, aPos.y, 0.0f, 1.0f);
}

