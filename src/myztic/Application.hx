package myztic;

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

        setGLAttrib( SDL_GL_RED_SIZE, 5 );
        setGLAttrib( SDL_GL_GREEN_SIZE, 5 );
        setGLAttrib( SDL_GL_BLUE_SIZE, 5 );
        setGLAttrib( SDL_GL_DEPTH_SIZE, 16 );
        setGLAttrib( SDL_GL_DOUBLEBUFFER, 1 );

        // TODO: customizeability
        final win = Window.create({name: "Myztic Engine", flags: SDL_WINDOW_OPENGL | SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE}, 
            DisplayHandler.monitors[0]);
        windows[win.backend.id] = win;
        focusID = win.backend.id;

        //glContexts[0] = SDL.GL_CreateContext(windows[0]);
        final gladResult:Int = Glad.gladLoadGLLoader(untyped __cpp__('(GLADloadproc)SDL_GL_GetProcAddress'));
        if (gladResult == 0)
            throw 'Failed to initialize GLAD! Most likely outdated OpenGL Version, Required: OpenGL 3.3, ERROR CODE: $gladResult';
        
        var glV:String;
        try { glV = OpenGL.getString(OpenGL.GL_VERSION); }
        catch(e) { throw 'Could not automatically get current OpenGL version. Please check manually. (GL 3.3 is required) [ERROR::$e]'; }

        //i am actually so sorry
        if((Glad.glVersion.major == 3 && Glad.glVersion.minor != 3) || (Glad.glVersion.major != 4)) 
            throw 'OpenGL version 3.3 is not supported on this device.
            \nCheck if your drivers are installed properly and if your GPU supports GL 3.3.
            \nRegistered Version: $glV';
        
        opengl.OpenGL.glViewport(0, 0, focusedWindow().width, focusedWindow().height); // Set Viewport for first time init
        focusedWindow().switchScene(initialScene);
        
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