package myztic.graphics.backend;

import opengl.OpenGL;

import cpp.Pointer;
import cpp.Star;

using cpp.Native;

class VAO{
    public var handle:GLuint;

    public function new(handle:GLuint){
        this.handle = handle;
    }

    public static inline function make():VAO{
        final vao:VAO = new VAO(-9);

        OpenGL.glGenVertexArrays(1, vao.handle.addressOf());
        #if MYZTIC_DEBUG_GL if (vao.handle == -9) throw 'Could not generate a vertex array object'; #end

        return vao;
    }

    public inline function bindVertexArray():Void
        OpenGL.glBindVertexArray(handle);

    public static inline function unbindGLVertexArray():Void
        OpenGL.glBindVertexArray(0);

    //todo: yanni change this
    public inline static function makeArr(n:Int):Array<VAO>{
        final ptr:Star<GLuint> = Native.malloc(GLuint.sizeof() * n);

        OpenGL.glGenVertexArrays(n, ptr);

        return [for(uint in Pointer.fromStar(ptr).toUnmanagedArray(n)) new VAO(uint)];
    }

    public inline function deleteArrayObject():Void{
        final int:Int = -99;
        OpenGL.glGetIntegerv(OpenGL.GL_VERTEX_ARRAY_BINDING, int.addressOf());
        if (int == handle) OpenGL.glBindVertexArray(0);
        OpenGL.glDeleteBuffers(1, handle.addressOf());
    }
}