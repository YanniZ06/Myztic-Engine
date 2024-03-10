package myztic.helpers;

import cpp.Star;
import cpp.Char;
import cpp.Pointer;
import opengl.OpenGL;

using cpp.Native;

@:headerInclude('string')
@:headerInclude('iostream')
class ErrorHandler {
    /**
     * [Description] Automatically checks if this sdl function has ran successfully or not
     * @param resultCode the result code from the caller sdl function
     * @param posInfo ignore this parameter, reserved
     * @return Void
     */
    public static function checkSDLError(resultCode:Int, ?posInfo:haxe.PosInfos):Void
        if(resultCode != 0) throw 'Could not run this SDL function with resultCode: $resultCode\nline: ${posInfo.lineNumber} class: ${posInfo.className}\nSDL ERROR INFO: ${sdl.SDL.getError()}';



    public static function checkShaderCompileStatus(shader:GLuint):Void{
        final result:Int = -44646;
        OpenGL.glGetShaderiv(shader, OpenGL.GL_COMPILE_STATUS, result.addressOf());
        if (!convertCPPBool(result)){
            var arr:Star<Char> = Native.malloc(4096);
            OpenGL.glGetShaderInfoLog(shader, 4096, null, cast arr);
            var us:UnicodeString = new UnicodeString("");
            var ptr:Pointer<Char> = Pointer.fromStar(arr);

            for (char in ptr.toUnmanagedArray(4096))
                us += String.fromCharCode(char);
            
            
            throw 'SHADER COULD NOT COMPILE, LOG: ' + us;
        }
    }

    /**
     * [Description] Converts a CPP Bool (int) into a haxe bool (true or false)
     * @return Bool
     */
    public static inline function convertCPPBool(result:Int):Bool
        return result == 1;
}