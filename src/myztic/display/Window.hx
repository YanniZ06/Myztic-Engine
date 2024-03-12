package myztic.display;

import sdl.GLContext;
import sdl.SDL;

import myztic.helpers.ErrorHandler.checkSDLError;
import myztic.display.windowUtils.WindowParams;
import myztic.display.windowUtils.Fps;
import myztic.display.backend.WinBackend;
import myztic.display.DisplayHandler as Display;

class Window { // todo: make this more fleshed out
    /**
     * The name of this window.
     */
    public var name(get, set):String;
    /**
     * This windows' left corner x position in pixels.
     */
    public var x(get, set):Int;
    /**
     * This windows' upper corner y position in pixels.
     */
    public var y(get, set):Int;

    /**
     * This windows' width in pixels.
     */
    public var width(get, set):Int;
    /**
     * This windows' height in pixels.
     */
    public var height(get, set):Int;

    /**
     * This windows' fps settings.
     */
    public var fps(default, null):Fps; // todo: implement

    /**
     * Backend values of this Window, for low level operations.
     */
    public var backend(default, null):WinBackend;
    
    private var _name:String;
    private var _x:Int;
    private var _y:Int;
    private var _width:Int;
    private var _height:Int;

    private function new(fps:Int) {
        backend = new WinBackend(this);
        this.fps = new Fps(fps);
    }

    public static function create(params:WindowParams):Window {
        var win = new Window(params.fps ?? Application.globalFps.max);

        //load displaymode in application init lol!!
        Display.currentMode = SDL.getCurrentDisplayMode(0);
        
        final size = params.init_scale ?? [cast Display.currentMode.w / 2, cast Display.currentMode.h / 2];
        final pos = params.init_pos ?? [cast (Display.currentMode.w - size[0]) / 2, cast (Display.currentMode.h - size[1]) / 2];
        final _flags:Int = (params.flags ?? 0) | SDL_WINDOW_OPENGL;
        
        win.backend.handle = SDL.createWindow(params.name, pos[0], pos[1], size[0], size[1], _flags);
        @:privateAccess {
            win._name = params.name;
            win._x = pos[0]; win._y = pos[1];
            win._width = size[0]; win._height = size[1];
        }


        win.backend.glContext = SDL.GL_CreateContext(win.backend.handle);
        checkSDLError(SDL.GL_MakeCurrent(win.backend.handle, win.backend.glContext));

        return win;
    }

    inline function set_name(v:String):String {
        SDL.setWindowTitle(backend.handle, v);
        return _name = v;
    }

    inline function set_x(v:Int):Int {
        SDL.setWindowPosition(backend.handle, v, _y);
        return _x = v;
    }

    inline function set_y(v:Int):Int {
        SDL.setWindowPosition(backend.handle, _x, v);
        return _y = v;
    }

    inline function get_name():String return _name;
    inline function get_x():Int return _x;
    inline function get_y():Int return _y;

    inline function set_width(v:Int):Int {
        SDL.setWindowSize(backend.handle, v, _height);
        return _width = v;
    }

    inline function set_height(v:Int):Int {
        SDL.setWindowSize(backend.handle, _width, v);
        return _height = v;
    }

    inline function get_width():Int return _width;
    inline function get_height():Int return _height;
}