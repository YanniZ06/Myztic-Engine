package myztic.graphics.backend;

import myztic.helpers.ErrorHandler.checkGLError;
import myztic.graphics.Bindable;

import opengl.OpenGL.GLfloat;
import opengl.OpenGL.GLuintPointer;
import opengl.OpenGL.GLuint;
import opengl.OpenGL as GL;

import cpp.Float32;
import myztic.helpers.StarArray;
import cpp.Pointer;
import cpp.Star;
import cpp.UInt32;

using cpp.Native;

class VBO implements Bindable<StarArray<GLfloat>, Int, Int> {
    public var handle:GLuint;

    function new(buf:GLuint) {
        handle = buf;
    }

    public static inline function make():VBO {
        final ret:VBO = new VBO(-99);

        GL.glGenBuffers(1, ret.handle.addressOf());
        checkGLError();
        #if MYZTIC_DEBUG_GL if (ret.handle == -99) throw 'Could not generate a vertex buffer object'; #end
        return ret;
    }

    public function fill(?vertices:StarArray<GLfloat>, ?fillType:Int, ?reserve_:Int):Void {
        #if MYZTIC_DEBUG_GL
        final currentBoundVertexBuffer:cpp.Int32 = -55464;
        GL.glGetIntegerv(GL.GL_ARRAY_BUFFER_BINDING, currentBoundVertexBuffer.addressOf());
        checkGLError();

        if (currentBoundVertexBuffer == -55464) throw 'COULD NOT GET CURRENT BOUND VERTEX BUFFER OBJECT'; 
        else if(currentBoundVertexBuffer != handle) trace('[[WARNING]]: Trying to modify data of vbo: $currentBoundVertexBuffer from the unbound buffer $handle');
        #end

        GL.glBufferData(GL.GL_ARRAY_BUFFER, GLfloat.sizeof() * vertices.length, cast vertices.data, fillType);
        checkGLError();
    }

    public inline function bind():Void {
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, handle);
        checkGLError();
    }

    public inline function unbind():Void {
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, 0);
        checkGLError();
    }

    public static inline function makeNum(n:Int):Array<VBO> {
        var ptr:StarArray<GLuint> = new StarArray<GLuint>(n);
        GL.glGenBuffers(n, ptr.data);
        checkGLError();

        return [for(n_vbo in 0...n) new VBO(ptr.get(n_vbo))];
    }

    public inline function delete():Void {
        final int:Int = -99;
        GL.glGetIntegerv(GL.GL_ARRAY_BUFFER_BINDING, int.addressOf());
        checkGLError();
        
        if (int == handle) GL.glBindBuffer(GL.GL_ARRAY_BUFFER, 0);
        GL.glDeleteBuffers(1, handle.addressOf());
        checkGLError();
    }

    // public inline function ptr():Star<GLuint> 
}