package graphics.oglh;

import opengl.GL;
import cpp.Star;
import cpp.UInt32;

class VBO {
    public var handle:Int;
    function new(buf:Int) {
        handle = buf;
    }

    public static inline function make():VBO {
        var a:Array<Int> = [];

        GL.glGenBuffers(1, a);
        return new VBO(a[0]);
    }

    public static inline function makeNum(n:Int):Array<VBO> {
        var a:Array<Int> = [];

        GL.glGenBuffers(n, a);
        var vbos:Array<VBO> = [];

        for(vbo in a) vbos.push(new VBO(vbo));
        return vbos;
    }

    // public inline function ptr():Star<Int> 
}