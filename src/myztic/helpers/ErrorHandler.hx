package myztic.helpers;

import cpp.Star;
import cpp.Char;
import cpp.Pointer;
import opengl.OpenGL as GL;
import opengl.OpenGL.GLuint;

using cpp.Native;

class ErrorHandler {
    /**
     * [Description] Automatically checks if this sdl function has ran successfully or not
     * @param resultCode the result code from the caller sdl function
     * @param posInfo ignore this parameter, reserved
     * @return Void
     */
    public static function checkSDLError(resultCode:Int, ?posInfo:haxe.PosInfos):Void
        if(resultCode != 0) throw 'Could not run this SDL function with resultCode: $resultCode\nline: ${posInfo.lineNumber} class: ${posInfo.className}\nSDL ERROR INFO: ${sdl.SDL.getError()}';

    /**
     * [Description] Automatically checks if a GL error has occured
     * @param posInfo reserved
     */
    public static function checkGLError(?posInfo:haxe.PosInfos):Void
    {
        var result:Int = GL.glGetError();

        if (result == 0)
            return; 

        while(result != 0){
            trace('Got a GL error from line: ${posInfo.lineNumber}, file: ${posInfo.fileName}, method name: ${posInfo.methodName}\nWith code: ${
                switch(result) {
                    case GL.GL_INVALID_ENUM: "GL_INVALID_ENUM";
                    case GL.GL_INVALID_VALUE: "GL_INVALID_VALUE";
                    case GL.GL_INVALID_OPERATION: "GL_INVALID_OPERATION";
                    case GL.GL_INVALID_FRAMEBUFFER_OPERATION: "GL_INVALID_FRAMEBUFFER_OPERATION";
                    case GL.GL_OUT_OF_MEMORY: "GL_OUT_OF_MEMORY";
                    default: "UNKNOWN ERROR, CODE: " + result;
                }
            }'
            );
            result = GL.glGetError();
        }

        throw "GL Errors traced, throwing to stop application";
    }

    public static function checkShaderCompileStatus(shader:GLuint):Void{
        final result:Int = -44646;
        GL.glGetShaderiv(shader, GL.GL_COMPILE_STATUS, result.addressOf());
        if (!convertCPPBool(result)) {
            var arr:Star<Char> = Native.malloc(4096);
            GL.glGetShaderInfoLog(shader, 4096, null, cast arr);
            var us:UnicodeString = new UnicodeString("");
            var ptr:Pointer<Char> = Pointer.fromStar(arr);

            for (char in ptr.toUnmanagedArray(4096))
                us += String.fromCharCode(char);
            
            
            throw 'SHADER COULD NOT COMPILE, LOG: ' + us;
        }
    }

    //TODO: WRITE A FUNCTION THAT CHECKS OUT GL AND CHECKS FOR ERRORS

    /**
     * [Description] Converts a CPP Bool (int) into a haxe bool (true or false)
     * @return Bool
     */
    public static inline function convertCPPBool(result:Int):Bool
        return result == 1;
}