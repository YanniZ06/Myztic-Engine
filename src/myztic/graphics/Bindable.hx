package myztic.graphics;

interface Bindable<ArgOne, ArgTwo, ArgThree> {
    public function bind():Void;
    public function unbind():Void;
    //three arguments at max (following Texture2D as it's the highest amount of arguments for filling)
    public function fill(?argOne:ArgOne, ?argTwo:ArgTwo, ?argThree:ArgThree):Void;
    public function delete():Void;
}