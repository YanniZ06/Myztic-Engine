package graphics.oglh;

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
        final vertexArrayObject:GLuint = -9;

        OpenGL.glGenVertexArrays(1, vertexArrayObject.addressOf());
        #if MYZTIC_DEBUG_GL if (vertexArrayObject == -9) throw 'Could not generate a vertex array object'; #end

        return new VAO(vertexArrayObject);
    }

    public inline function bindVertexArray():Void
        OpenGL.glBindVertexArray(handle);

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