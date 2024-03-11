package myztic.display;

import sdl.GLContext;
import sdl.SDL;

import myztic.helpers.ErrorHandler.checkSDLError;
import myztic.display.windowUtils.WindowParams;
import myztic.display.DisplayHandler as Display;

class Window { // todo: make this more fleshed out
    public var id:Int;
    public var handle:sdl.Window;
    public var glContext:GLContext;

    private function new() {}
    public static function create(params:WindowParams):Window {
        var win = new Window();

        //load displaymode
        Display.currentMode = SDL.getCurrentDisplayMode(0);
        
        final size = params.init_scale ?? [cast Display.currentMode.w / 2, cast Display.currentMode.h / 2];
        final pos = params.init_pos ?? [cast (Display.currentMode.w - size[0]) / 2, cast (Display.currentMode.h - size[1]) / 2];
        final _flags:Int = (params.flags ?? 0) | SDL_WINDOW_OPENGL;
        
        win.handle = SDL.createWindow(params.name, pos[0], pos[1], size[0], size[1], _flags);

        win.glContext = SDL.GL_CreateContext(win.handle);
        checkSDLError(SDL.GL_MakeCurrent(win.handle, win.glContext));

        return win;
    }
}