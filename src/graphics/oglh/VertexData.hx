package graphics.oglh;

import cpp.Native;
import cpp.Float32;

abstract VertexData(Array<Float32>) from Array<Float32> to Array<Float32> {
    public var x:Float32;
    public var y:Float32;
    public var z:Float32;
    public var size(get,never):Int;

    inline function get_size():Int return Native.sizeof(Float32) * 3;

    @:to
    function toArray():Array<Float32> {
        return [x,y,z];
        
        var arr:Array<Float32> = [];
        // arr.
    }
}