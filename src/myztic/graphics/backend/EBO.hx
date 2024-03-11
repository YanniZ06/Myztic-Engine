package myztic.graphics.backend;

import cpp.Float32;
import myztic.helpers.StarArray;
import opengl.OpenGL;

using cpp.Native;

class EBO{
    public var handle:GLuint;

    public function new(handle:GLuint){
        this.handle = handle;
    }

    public static inline function make():EBO{
        //create new element buffer object
        final ret:EBO = new EBO(-888);

        OpenGL.glGenBuffers(1, ret.handle.addressOf());

        #if MYZTIC_DEBUG_GL if(ret.handle == -888) throw 'Could not generate element buffer object'; #end    

        return ret;
    }

    public static inline function makeNum(n:Int):Array<EBO>{
        final ptr:StarArray<GLuint> = new StarArray<GLuint>(n);

        OpenGL.glGenBuffers(n, ptr.data);

        return [for (ebo in 0...n) new EBO(ptr.get(ebo))];
    }

    public inline function bind():Void
        OpenGL.glBindBuffer(OpenGL.GL_ELEMENT_ARRAY_BUFFER, handle);

    public inline function changeElementBufferData(indices:StarArray<Float32>):Void{
        #if MYZTIC_DEBUG_GL
        final currentBoundElementBuffer:cpp.Int32 = -55464;
        OpenGL.glGetIntegerv(OpenGL.GL_ELEMENT_ARRAY_BUFFER_BINDING, currentBoundElementBuffer.addressOf());

        if (currentBoundElementBuffer == -55464) throw 'COULD NOT GET CURRENT BOUND ELEMENT BUFFER OBJECT'; 
        else if(currentBoundElementBuffer != handle) trace('[[WARNING]]: Trying to modify data of ebo: $currentBoundElementBuffer from the unbound element buffer $handle');
        #end
        OpenGL.glBufferData(OpenGL.GL_ELEMENT_ARRAY_BUFFER, indices.size, cast indices.data, OpenGL.GL_STATIC_DRAW);
    }

    public inline function deleteBuffer():Void{
        final int:Int = -99;
        OpenGL.glGetIntegerv(OpenGL.GL_ELEMENT_ARRAY_BUFFER_BINDING, int.addressOf());
        if (int == handle) OpenGL.glBindBuffer(OpenGL.GL_ELEMENT_ARRAY_BUFFER, 0);
        OpenGL.glDeleteBuffers(1, handle.addressOf());
    }
}