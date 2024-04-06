package myztic.graphics.backend;

import opengl.OpenGL;
import myztic.helpers.StarArray;
import myztic.helpers.ErrorHandler.checkGLError;
import myztic.graphics.Bindable;

import cpp.Pointer;
import cpp.Star;

using cpp.Native;

class VAO implements Bindable<Int, Int, Int> {
    public var handle:GLuint;

    public function new(handle:GLuint) {
        this.handle = handle;
    }

    public static inline function make():VAO {
        final vao:VAO = new VAO(-9);

        OpenGL.glGenVertexArrays(1, vao.handle.addressOf());
        checkGLError();
        #if MYZTIC_DEBUG_GL if (vao.handle == -9) throw 'Could not generate a vertex array object'; #end

        return vao;
    }

    public inline function bind():Void {
        OpenGL.glBindVertexArray(handle);
        checkGLError();
    }

    public inline function unbind():Void {
        OpenGL.glBindVertexArray(0);
        checkGLError();
    }

    //DO NOT USE, EMPTY FUNCTION I HATE HAXE FOR THIS
    public inline function fill(?_r1:Int, ?_r2:Int, ?_r3:Int):Void {}

    public inline static function makeArr(n:Int):Array<VAO> {
        var ptr:StarArray<GLuint> = new StarArray<GLuint>(n);
        OpenGL.glGenVertexArrays(n, ptr.data);
        checkGLError();

        return [for(n_vao in 0...n) new VAO(ptr.get(n_vao))];
    }

    public inline function delete():Void {
        final int:Int = -99;
        OpenGL.glGetIntegerv(OpenGL.GL_VERTEX_ARRAY_BINDING, int.addressOf());
        checkGLError();

        if (int == handle) OpenGL.glBindVertexArray(0);
        OpenGL.glDeleteBuffers(1, handle.addressOf());
        checkGLError();
    }
}