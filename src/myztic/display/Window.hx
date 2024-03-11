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

    public var name(get, set):String;
    public var x(get, set):Int;
    public var y(get, set):Int;

    public var width(get, set):Int;
    public var height(get, set):Int;

    
    private var _name:String;
    private var _x:Int;
    private var _y:Int;
    private var _width:Int;
    private var _height:Int;

    private function new() {}
    public static function create(params:WindowParams):Window {
        var win = new Window();

        //load displaymode
        Display.currentMode = SDL.getCurrentDisplayMode(0);
        
        final size = params.init_scale ?? [cast Display.currentMode.w / 2, cast Display.currentMode.h / 2];
        final pos = params.init_pos ?? [cast (Display.currentMode.w - size[0]) / 2, cast (Display.currentMode.h - size[1]) / 2];
        final _flags:Int = (params.flags ?? 0) | SDL_WINDOW_OPENGL;
        
        win.handle = SDL.createWindow(params.name, pos[0], pos[1], size[0], size[1], _flags);
        @:privateAccess {
            win._name = params.name;
            win._x = pos[0]; win._y = pos[1];
            win._width = size[0]; win._height = size[1];
        }


        win.glContext = SDL.GL_CreateContext(win.handle);
        checkSDLError(SDL.GL_MakeCurrent(win.handle, win.glContext));

        return win;
    }

    inline function set_name(v:String):String {
        SDL.setWindowTitle(handle, v);
        return _name = v;
    }

    inline function set_x(v:Int):Int {
        SDL.setWindowPosition(handle, v, _y);
        return _x = v;
    }

    inline function set_y(v:Int):Int {
        SDL.setWindowPosition(handle, _x, v);
        return _y = v;
    }

    inline function get_name():String return _name;
    inline function get_x():Int return _x;
    inline function get_y():Int return _y;

    inline function set_width(v:Int):Int {
        SDL.setWindowSize(handle, v, _height);
        return _width = v;
    }

    inline function set_height(v:Int):Int {
        SDL.setWindowSize(handle, _width, v);
        return _height = v;
    }

    inline function get_width():Int return _width;
    inline function get_height():Int return _height;
}