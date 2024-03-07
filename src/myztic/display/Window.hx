package myztic.display;

import sdl.SDL;
import myztic.display.windowUtils.WindowParams;
import myztic.display.DisplayHandler as Display;

class Window {
    public var id:Int;
    public var handle:sdl.Window;

    private function new() {}
    public static function create(params:WindowParams):Window {
        var win = new Window();
        
        // TODO: test this concoction
        final size = params.init_scale ?? [cast Display.currentMode.w / 2, cast Display.currentMode.h / 2];
        final pos = params.init_pos ?? [cast (Display.currentMode.w - size[0]) / 2, cast (Display.currentMode.h - size[1]) / 2];
        final _flags = (flags ?? 0) | SDL_WINDOW_OPENGL;
        win.handle = SDL.createWindow(params.title, pos[0], pos[1], size[0], size[1], _flags);
    }
}