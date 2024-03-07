package sdl_extend;

import sdl.Window;
import sdl.SDL;

class Video {
    public static inline function getWindowDisplayIndex(window:Window):Int {
        return untyped __cpp__('SDL_GetWindowDisplayIndex(window)');
    }
}