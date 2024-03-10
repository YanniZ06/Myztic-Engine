package graphics.oglh;



import myztic.helpers.ErrorHandler;
import myztic.helpers.Tools;
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

    public inline function changeVertexBufferData(vertices:Array<GLfloat>, drawType:Int):Void{
        final currentBoundVertexBuffer:cpp.Int32 = -55464;
        GL.glGetIntegerv(GL.GL_ARRAY_BUFFER_BINDING, currentBoundVertexBuffer.addressOf());
        if (currentBoundVertexBuffer == -55464) throw 'COULD NOT GET CURRENT BOUND VERTEX BUFFER OBJECT'; 
        else if(currentBoundVertexBuffer != handle) trace('[[WARNING]]: Trying to modify data of vbo: $currentBoundVertexBuffer from the unbound buffer $handle');
        GL.glBufferData(GL.GL_ARRAY_BUFFER, GLfloat.sizeof() * vertices.length, Tools.get_void_ptr_from_array(vertices), drawType);
        
    }

    public inline function bindVertexBuffer():Void
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, handle);

    // todo: make this return a stararray and also use one to spare ourselves the necessity of..
    public static inline function makeNum(n:Int):Array<VBO> {
        var ptr:Star<GLuint> = Native.malloc(n * GLuint.sizeof()); // Allocate a pointer big enough to host our VBO's
        
        GL.glGenBuffers(n, ptr);

        return [for(vbo in Pointer.fromStar(ptr).toUnmanagedArray(n)) new VBO(vbo)]; // todo: .. this for-loop.
    }

    public inline function deleteBuffer():Void{
        final int:Int = -99;
        GL.glGetIntegerv(GL.GL_ARRAY_BUFFER_BINDING, int.addressOf());
        if (int == handle) GL.glBindBuffer(GL.GL_ARRAY_BUFFER, 0);
        GL.glDeleteBuffers(1, handle.addressOf());
    }

    // public inline function ptr():Star<GLuint> 
}