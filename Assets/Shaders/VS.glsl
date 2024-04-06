#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aCol;
layout (location = 2) in vec2 aTexCoords;

out vec3 vertCol;
out vec2 texCoords;

uniform mat4 world;
uniform mat4 camView;
uniform mat4 projection;
        
void main()
{
    gl_Position = camView * world * projection *  vec4(aPos, 1.0);
    vertCol = aCol;
    texCoords = aTexCoords;
}