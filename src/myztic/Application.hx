package myztic;

import myztic.display.windowUtils.WindowParams;


import myztic.display.DisplayHandler;
import myztic.display.windowUtils.Fps;
import myztic.helpers.ErrorHandler;
import myztic.Scene;
import cpp.Function;
import sdl.SDL;
import sdl.SDL.GL_SetAttribute as setGLAttrib;

import opengl.OpenGL;
import glad.Glad; 

import myztic.display.Window;

// TODO: VERY BIG: MAKE SURE CONTEXT SPECIFIC OPERATIONS LIKE VIEWPORT ARE DONE PER-WINDOW!!!
class Application {
    public static var globalFps:Fps; // todo: implement

    /**
     * All windows bound to this application, mapped to their respective IDs (obtained via `window.backend.id`)
     */
    public static var windows:Map<Int, Window> = [];
    public static var nWindows:Int = -1;

    private static var focusID:Int;
    
    public static inline function focusedWindow():Window
        return windows[focusID];
    
    // todo: file for initial window and app settings on startup (like window position and size, name, and other funky things)
    public static function initMyztic(initialScene:Scene):Void{
        if(SDL.init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_GAMECONTROLLER | SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC) != 0) {
            throw 'Error initializing SDL subsystems: ${SDL.getError()}';
        }
        globalFps = new Fps(60);
        DisplayHandler.refresh_AvailableMonitors();

        final GL_ATTRIBS:Map<SDLGLAttr, Int> = [ SDL_GL_RED_SIZE => 5, SDL_GL_GREEN_SIZE => 5, SDL_GL_BLUE_SIZE => 5,
            SDL_GL_DEPTH_SIZE => 16, SDL_GL_DOUBLEBUFFER => 1 ];
        for(attr => val in GL_ATTRIBS) SDL.GL_SetAttribute(attr, val);

        // TODO: customizeability
        var win:Window;
        @:privateAccess {
            final params:WindowParams = {name: "Myztic Engine", init_scene: initialScene,
                flags: SDL_WINDOW_OPENGL | SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE};
            final monitor = DisplayHandler.monitors[0];

            win = new Window(params.fps ?? Application.globalFps.max);
            win.monitor = monitor ?? DisplayHandler.getCurrentMonitor() ?? DisplayHandler.monitors[0];

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
            windows[win.backend.id] = win;
        }
        
        ErrorHandler.checkSDLError(SDL.GL_MakeCurrent(win.backend.handle, win.backend.glContext));
        focusID = win.backend.id;
        nWindows = 1; // Resolve -1 (Initial Window ID)

        trace(win.monitor);

        //glContexts[0] = SDL.GL_CreateContext(windows[0]);
        final gladResult:Int = Glad.gladLoadGLLoader(untyped __cpp__('(GLADloadproc)SDL_GL_GetProcAddress'));
        if (gladResult == 0)
            throw 'Failed to initialize GLAD! Most likely outdated OpenGL Version, Required: OpenGL 3.3, ERROR CODE: $gladResult'; // What?
        
        var glV:String;
        try { glV = OpenGL.getString(OpenGL.GL_VERSION); }
        catch(e) { throw 'Could not automatically get current OpenGL version. Please check manually. (GL 3.3 is required) [ERROR::$e]'; }

        //i am actually so sorry
        if((Glad.glVersion.major == 3 && Glad.glVersion.minor != 3) || (Glad.glVersion.major != 4)) 
            throw 'OpenGL version 3.3 is not supported on this device.
            \nCheck if your drivers are installed properly and if your GPU supports GL 3.3.
            \nRegistered Version: $glV';
        
        opengl.OpenGL.glViewport(0, 0, win.width, win.height); // Set Viewport for first time init
        win.switchSceneVirgin(initialScene);
        
        #if MYZTIC_DEBUG_GL
        trace("RUNNING ON OPENGL VERSION: " + glV);
        trace("GLSL VERSION IS: " + OpenGL.getString(OpenGL.GL_SHADING_LANGUAGE_VERSION));
        trace('VENDOR: ${OpenGL.getString(OpenGL.GL_VENDOR)}');
        #end
        // trace('Current context is made context?? - ${SDL.GL_GetCurrentContext() == windows[0].backend.glContext}');


        // Exiting our application from here on out, we can clean up everything!!
        // todo: uncomment this when update loop was moved here
        // destroyApplication();
    }

    inline static function destroyApplication():Void { // Cleans up everything nice and tidy
        for(id=>win in windows) { win.destroy(); }
        SDL.quit();

        Sys.exit(0);
    }
}