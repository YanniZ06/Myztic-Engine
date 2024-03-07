package graphics.oglh;

import opengl.GL;
import cpph.StarArray;
/**
 * GL Helper class for bindings and the like
 */
@:keep
@:include('linc_opengl.h')
extern class GLH {
    inline static function getString(name:Int):cpp.ConstCharStar { 
        return untyped __cpp__("(const char*)glGetString({0})", name);
    }

    inline static function getStringi(name:Int, index:Int):cpp.ConstCharStar { 
        return untyped __cpp__("(const char*)glGetStringi({0},{1})", name,index);
    }

    // const_cast<const void*>(ptr)
    // same as the below but safer??
    // (const void*) ptr
    inline static function bufferData(target:Int, size:Int, data:StarArray<cpp.Float32>, usage:Int) : Void { 
        untyped __cpp__("glBufferData({0}, {1}, const_cast<const void*>({2}), {3})", target, size, data.data, usage); 
    }
}