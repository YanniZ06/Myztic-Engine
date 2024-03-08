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
        if (a == -9) throw 'Could not generate a vertex buffer object';
        return new VBO(a);
    }

    public static inline function makeNum(n:Int):Array<VBO> {
        final a:Array<GLuint> = [];
        final ptr:GLuintPointer = GLuintPointer.fromArray(a);
        
        GL.glGenBuffers(n, ptr);
        var vbos:Array<VBO> = [];
        
        for(vbo in Pointer.fromStar((cast ptr : Star<GLuint>)).toUnmanagedArray(n)) vbos.push(new VBO(vbo));
        return vbos;
    }

    // public inline function ptr():Star<Int> 
}