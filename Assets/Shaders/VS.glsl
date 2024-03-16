#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aCol;
layout (location = 2) in vec2 aTexCoords;

out vec3 vertCol;
out vec2 texCoords;
        
void main()
{
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    vertCol = aCol;
    texCoords = aTexCoords;
}