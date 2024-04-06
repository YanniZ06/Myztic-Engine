package myztic.display.backend;

import sdl.GLContext;
import myztic.display.Window;
/**
 * Backend variables for `myztic.display.Window`.
 * 
 * Used to keep public low-level access without forcing it into the autocompletion.
 */
 @:headerInclude('iostream')
class WinBackend {
    /**
     * SDL Window ID.
     */
    public var id:Int;
    /**
     * SDL Window Handle.
     */
    public var handle:sdl.Window;
    /**
     * OpenGL Context associated with this window.
     */
    public var glContext:GLContext;

    /**
     * Myztic Window this backend is attached to.
     */
    private var parent:Window;

    public function new(parent:Window) {
        this.parent = parent;
    }

    public static function logContextID(c:GLContext) {
        untyped __cpp__('std::cout << "WinBackend.hx Context Log: " << {0} << "\\n"', c);
    }
}