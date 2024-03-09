package graphics.oglh;

import cpp.Pointer;
import opengl.OpenGL.GLuintPointer;
import cpph.StarArray;
import opengl.OpenGL.GLuint;
import opengl.OpenGL as GL;
import cpp.Star;
import cpp.UInt32;

using cpp.Native;

class VBO {
    public var handle:GLuint;
    function new(buf:GLuint) {
        handle = buf;
    }

    public static inline function make():VBO {
        var a:GLuint = -9;

        GL.glGenBuffers(1, a.addressOf());
        #if MYZTIC_DEBUG_GL if (a == -9) throw 'Could not generate a vertex buffer object'; #end
        return new VBO(a);
    }

    // todo: make this return a stararray and also use one to spare ourselves the necessity of..
    public static inline function makeNum(n:Int):Array<VBO> {
        var ptr:Star<GLuint> = Native.malloc(n * 4); // Allocate a pointer big enough to host our VBO's
        
        GL.glGenBuffers(n, ptr);
        var vbos:Array<VBO> = [];
        
        for(vbo in Pointer.fromStar(ptr).toUnmanagedArray(n)) vbos.push(new VBO(vbo)); // todo: .. this for-loop.
        return vbos;
    }

    // public inline function ptr():Star<GLuint> 
}