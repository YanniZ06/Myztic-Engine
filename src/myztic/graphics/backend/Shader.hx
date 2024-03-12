package myztic.graphics.backend;

import cpp.Float32;
import myztic.helpers.ErrorHandler;
import opengl.StringPointer;
import opengl.OpenGL;
import sys.io.File;

using cpp.Native;

class Shader
{
    public var handle:GLuint;

    public function new(shaderType:GLenum, file:String) {
        handle = OpenGL.glCreateShader(shaderType);
        OpenGL.glShaderSource(handle, 1, StringPointer.fromString(File.getContent('Assets/Shaders/$file')), null);
        OpenGL.glCompileShader(handle);
        
        ErrorHandler.checkShaderCompileStatus(handle);
    }

    public inline function deleteShader():Void
        OpenGL.glDeleteShader(handle);
}

//todo: Write a macro that generates functions for modifying uniforms
class ShaderProgram 
{
    public var handle:GLuint;
    public var uniforms:Map<String, Int> = [];

    public function new() {
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

    public function getUniformLocation(uniformVariable:String):Int {
        if (uniforms.exists(uniformVariable)) return uniforms.get(uniformVariable);

        final uniformLocation:Int = OpenGL.glGetUniformLocation(handle, uniformVariable);
        uniforms.set(uniformVariable, uniformLocation);
        return uniformLocation;
    }

    public function modifyUniformVector3(input:Array<Float32>, location:Int):Void {
        final currentBoundProgram:Int = 0;
        OpenGL.glGetIntegerv(OpenGL.GL_CURRENT_PROGRAM, currentBoundProgram.addressOf());
        if (currentBoundProgram != handle) trace("[[WARNING]]: CURRENT BOUND PROGRAM IS NOT THE SAME AS THE CLASS YOURE CALLING IT FROM, CURRENTLY BOUND: " + currentBoundProgram + " CLASS HANDLE: " + handle);
        if (input.length > 4) {trace('MAX SIZE FOR MODIFYUNIFORMVECTOR IS 4');  return;}
        OpenGL.glUniform3f(location, input[0], input[1], input[2]);
    }
}