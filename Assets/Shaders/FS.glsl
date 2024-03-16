#version 330 core
out vec4 FragColor;
in vec3 vertCol;
in vec2 texCoords;

uniform sampler2D inputTexture;
        
void main()
{
    FragColor = texture(inputTexture, texCoords) * vec4(vertCol, 1.0f);
} 