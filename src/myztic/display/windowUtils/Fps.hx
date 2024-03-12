package myztic.display.windowUtils;

// todo: actually make fps be used for application AND windows, populate _used value in Application
/**
 * Object that eases access to fps related values.
 */
class Fps {
    public function new(maxDesired:Int) { max = maxDesired; }

    /**
     * The max fps cap set this window
     */
    public var max(default, set):Int;

    /**
     * The actually used fps for this window
     */
    public var used(get, never):Int;

    /**
     * Number of ms between each frame at a constant framerate.
     */
    public var msFrameTime(default, null):Float;

    @:allow(myztic.Application)
    private var _used:Int;

    inline function get_used():Int return _used;
    inline function set_max(v:Int):Int {
        msFrameTime = 1 / v;
        return max = _used = v;
    }
}