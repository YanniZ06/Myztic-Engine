#version 330 core
out vec4 FragColor;
in vec2 texCoords;

uniform sampler2D inputTexture;
        
void main()
{
    FragColor = texture(inputTexture, texCoords);
} 