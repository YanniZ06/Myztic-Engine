package cpph;

import cpp.Pointer;
import cpp.Star;

using cpp.Native;

class Tools{
    public static inline function get_void_ptr_from_array<T>(array:Array<T>):Star<cpp.Void>
        return cast Pointer.arrayElem(array, 0).ptr;

    //doesnt work because its type parameter'd, must find a way through this, do your thing yanni
    //@:generic
    //public static inline function get_void_ptr_from_obj<T>(obj:T):Star<cpp.Void>
    //    return null;
}