#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aCol;
layout (location = 2) in vec2 aTexCoords;

out vec3 vertCol;
out vec2 texCoords;

uniform mat4 transform;
        
void main()
{
    gl_Position = transform * vec4(aPos, 1.0);
    vertCol = aCol;
    texCoords = aTexCoords;
}