package myztic.util;

//! IMPORTANT: IF YOU ARE MODIFYING THIS YOU NEED TO MODIFY THE MACRO BUILD ASWELL, THIS IS CLASS IS JUST A PLACEHOLDER FOR DOCS!
/*
If you want to see the actual code of the StarArray, go to myztic.util.Macros.STRMacro.makeInstanceOf() !
*/
@:genericBuild(myztic.util.Macros.STRMacro.build())
class StarArray<T> {
    public var data:cpp.Star<T>;
    public var data_index(default, set):Int = 0;
    public var length:Int;
    public var size:Int;

    private var firstIndex:cpp.Star<T>; // THIS SHOULD NEVER CHANGE!!! but it perhaps could if you expand the memory this star uses, be cautious and wary of that!
    private var type_size:Int;

    public function new(expectedElements:Int = 1) {
    };
    
    public inline function get(index:Int):Null<T> {
        return null;
    }

    public inline function set(index:Int, value:T):Void {}

    public inline function getCurrent():Null<T> {
        return null;
    }

    public inline function setCurrent(value:T):Void {}


    inline function set_data_index(i:Int):Int { 
        return -1;
    }

    /**
     * Creates a StarArray from a haxe Array.
     * Only guaruanteed to work with basic types, as important information might be lost on conversions for more complex types.
     */
    /*@:generic
    public static function fromArray<T>(array:Array<T>):StarArray<T> {
        var strarr = new StarArray<T>(array.length);
        strarr.data = untyped __cpp__('({1}*){0}->Pointer()', array, T);
        strarr.currentIndex = 0;

        return strarr;
    }*/

    /*@:to
    public static function toArray<T>(strarr:StarArray<T>):Array<T> {
        untyped __cpp__('
            int (*c)[{0}] = (int(*)[{0}])new int[{0}];
        ', strarr.length);

        throw 'Die';
        return null;
    }*/
}
