#version 330

out vec4 fragment_color;

uniform vec3 color;

void main(void)
{
    fragment_color = vec4(color, 1.0f);
}

