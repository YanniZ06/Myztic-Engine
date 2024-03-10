package graphics.oglh;

import myztic.helpers.ErrorHandler;
import opengl.StringPointer;
import opengl.OpenGL;
import sys.io.File;

class Shader
{
    public var handle:GLuint;

    public function new(shaderType:GLenum, file:String){
        handle = OpenGL.glCreateShader(shaderType);
        OpenGL.glShaderSource(handle, 1, StringPointer.fromString(File.getContent('Assets/Shaders/$file')), null);
        OpenGL.glCompileShader(handle);
        ErrorHandler.checkShaderCompileStatus(handle);
    }

    public inline function deleteShader():Void
        OpenGL.glDeleteShader(handle);
}

class ShaderProgram 
{
    public var handle:GLuint;

    public function new(){
        handle = OpenGL.glCreateProgram();
    }

    public inline function link()
        OpenGL.glLinkProgram(handle);

    public inline function attachShader(shader:Shader):Void
        OpenGL.glAttachShader(handle, shader.handle);

    public inline function useProgram():Void
        OpenGL.glUseProgram(handle);

    public inline function deleteProgram():Void
        OpenGL.glDeleteProgram(handle);
}