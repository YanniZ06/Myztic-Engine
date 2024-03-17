package myztic.graphics.backend;

import haxe.io.Bytes;
import opengl.VoidPointer;
import opengl.OpenGL.GLuint;
import opengl.OpenGL as GL;
import myztic.helpers.ErrorHandler.checkGLError;

import format.png.*;
import sys.io.File;
import haxe.io.Bytes;
import haxe.io.BytesInput;

import myztic.helpers.StarArray;

using cpp.Native;

class Texture2D
{
    public var handle:GLuint;

    public function new(handle:GLuint) {
        this.handle = handle;
    }

    //todo: find a way to correctly do this instead of just gaslighting ourselves that it works
    public static function fromFile(fileName:String):Texture2D {
        var fileBytes:BytesInput = new BytesInput(File.getBytes('Assets/Images/$fileName'));
        var pngReader:Reader = new Reader(fileBytes);
        var readData:Data = pngReader.read();
        
        //dispose of fileBytes
        fileBytes.close();

        @:privateAccess
        pngReader.i.close();
        pngReader = null;
        fileBytes = null;
        cpp.vm.Gc.run(true);

        var imageHeader:format.png.Data.Header = Tools.getHeader(readData);
        final width:Int = imageHeader.width;
        final height:Int = imageHeader.height;
        //dispose of header
        imageHeader = null;
        cpp.vm.Gc.run(true);
        
        var imageBytes:Bytes = Tools.extract32(readData);
        //dispose of readData
        
        readData.clear();
        readData = null;
        cpp.vm.Gc.run(true);

        final ret:Texture2D = Texture2D.make();
        ret.bindTexture();
        ret.configureTexture();
        ret.setTextureData(width, height, imageBytes);
        //clear bytes
        imageBytes.fill(0, imageBytes.length, 0);
        imageBytes = null;
        cpp.vm.Gc.run(true);

        return ret;
    }

    public static inline function make():Texture2D {
        final ret:Texture2D = new Texture2D(-99);

        GL.glGenTextures(1, ret.handle.addressOf());
        checkGLError();
        #if MYZTIC_DEBUG_GL if (ret.handle == -99) throw 'Could not create texture'; #end
        return ret;
    }

    public inline static function makeArr(n:Int):Array<Texture2D> {
        var ptr:StarArray<GLuint> = new StarArray<GLuint>(n);
        GL.glGenTextures(n, ptr.data);
        checkGLError();

        return [for(n_texture in 0...n) new Texture2D(ptr.get(n_texture))];
    }

    public inline function bindTexture():Void {
        GL.glBindTexture(GL.GL_TEXTURE_2D, handle);
        checkGLError();
    }

    public static inline function unbindTexture():Void {
        GL.glBindTexture(GL.GL_TEXTURE_2D, 0);
        checkGLError();
    }

    public inline function deleteTexture():Void {
        GL.glDeleteTextures(1, handle.addressOf());
        checkGLError();
    }

    public inline function configureTexture():Void {
        //set the texture wrapping/filtering options (on the currently bound texture object)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_S, GL.GL_MIRRORED_REPEAT);
        checkGLError();
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_T, GL.GL_MIRRORED_REPEAT);
        checkGLError();

        //yanni said this will be for antialiasing off (mipmaps are enabled on this)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST_MIPMAP_NEAREST);
        checkGLError();
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
        checkGLError();
    }

    public inline function setTextureData( width:Int, height:Int, data:Bytes):Void{
        GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, GL.GL_RGBA, width, height, 0, GL.GL_BGRA, GL.GL_UNSIGNED_BYTE, VoidPointer.fromBytes(data));
        GL.glGenerateMipmap(GL.GL_TEXTURE_2D);
        checkGLError();
    }
}