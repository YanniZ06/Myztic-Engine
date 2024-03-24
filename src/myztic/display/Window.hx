package myztic.display;

import myztic.Application;

import sdl.GLContext;
import sdl.SDL;

import myztic.Scene;
import myztic.helpers.ErrorHandler.checkSDLError;
import myztic.display.DisplayHandler as Display;
import myztic.display.Monitor;
import myztic.display.windowUtils.WindowParams;
import myztic.display.windowUtils.Fps;
import myztic.display.backend.WinBackend;
import myztic.graphics.Renderer;

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

    /**
     * This windows' actively rendered Scene.
     */
    public var scene(default, null):Scene;

    /**
     * This windows' renderer object.
     */
    public var renderer(default, null):Renderer;

    /**
     * The monitor this window is being rendered on.
     */
    public var monitor(default, null):Monitor;
    
    private var _name:String;
    private var _x:Int;
    private var _y:Int;
    private var _width:Int;
    private var _height:Int;

    private function new(fps:Int) {
        backend = new WinBackend(this);
        renderer = new Renderer(this);

        this.fps = new Fps(fps);
    }

    /*
    #define SDL_WINDOWPOS_CENTERED_MASK    0x2FFF0000u
    #define SDL_WINDOWPOS_CENTERED_DISPLAY(X)  (SDL_WINDOWPOS_CENTERED_MASK|(X))
    #define SDL_WINDOWPOS_CENTERED         SDL_WINDOWPOS_CENTERED_DISPLAY(0)
    #define SDL_WINDOWPOS_ISCENTERED(X)    \
    (((X)&0xFFFF0000) == SDL_WINDOWPOS_CENTERED_MASK)
    */

    /**
     * Creates a new Window from the given parameters.
     * 
     * Note: The initial window created by the application is NOT created using this function, shadowing it will do nothing!
     * @param params The window parameters.
     * @param monitor Optional argument for the monitor this window should be rendered on, by default gets the first monitor.
     */
    public static function create(params:WindowParams, ?monitor:Monitor):Window {
        final oldContext = SDL.GL_GetCurrentContext();
        final oldWindow = SDL.GL_GetCurrentWindow();

        var win = new Window(params.fps ?? Application.globalFps.max);
        win.monitor = monitor ?? Display.getCurrentMonitor() ?? Display.monitors[0];

        //todo: monitor shit using SDL_WINDOWPOS_CENTERED_DISPLAY
        final size = params.init_scale ?? [cast win.monitor.width / 2, cast win.monitor.height / 2];
        final pos = params.init_pos ?? [cast (win.monitor.width - size[0]) / 2, cast (win.monitor.height - size[1]) / 2];
        final _flags:Int = (params.flags ?? 0) | SDL_WINDOW_OPENGL;
        
        win.backend.handle = SDL.createWindow(params.name, pos[0], pos[1], size[0], size[1], _flags);
        win._name = params.name;
        win._x = pos[0]; win._y = pos[1];
        win._width = size[0]; win._height = size[1];

        win.backend.id = SDL.getWindowID(win.backend.handle);
        win.backend.glContext = SDL.GL_CreateContext(win.backend.handle);

        win.switchSceneVirgin(params.init_scene);

        Application.windows[win.backend.id] = win;
        Application.nWindows++;

        if(oldWindow != null) SDL.GL_MakeCurrent(oldWindow, oldContext); // Set back to old context
        
        return win;
    }

    // Todo: add rendering!
    public inline function switchScene(input:Scene):Void {
        scene.unload(this);
        scene = input;
        scene.load(this);
    }

    @:allow(myztic.Application)
    @:noCompletion inline function switchSceneVirgin(input:Scene) {
        scene = input;
        scene.load(this);
    }

    // Todo: Gradually add onto this
    public function destroy():Void {
        scene.unload(this); // todo: figure out where this should go
        Application.windows.remove(backend.id);
        Application.nWindows--;
        SDL.destroyWindow(backend.handle);
        
        scene = null;
        name = null;
        fps = null;
    }

    private inline function toString() {
        return 'Window ${backend.id} ["$_name"]: $width x $height at position ($x | $y) running on ${fps.max} max fps';
    }

    private static inline final POS_CENTER_MASK:Int = 0x2FFF0000;
    private static inline function CENTER_POS_DISPLAY(x:Int) return (POS_CENTER_MASK | x);

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