#version 330 core
out vec4 FragColor;

uniform vec3 vertCol;
        
void main()
{
    FragColor = vec4(vertCol, 1.0f);
} 