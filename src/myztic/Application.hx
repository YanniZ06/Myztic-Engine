package myztic;

import myztic.helpers.ErrorHandler;
import cpp.Function;
import sdl.SDL;
import sdl.SDL.GL_SetAttribute as setGLAttrib;

import graphics.oglh.GLH;
import opengl.OpenGL;
import glad.Glad; 

import myztic.display.Window;

// TODO: VERY BIG: MAKE SURE CONTEXT SPECIFIC OPERATIONS LIKE VIEWPORT ARE DONE PER-WINDOW!!!
class Application {
    public static var windows:Array<Window> = [];

    public static inline function getMainWindow():Window
        return windows[0];
    
    public static function initMyztic():Void{
        if(SDL.init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_GAMECONTROLLER | SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC) != 0) {
            throw 'Error initializing SDL subsystems: ${SDL.getError()}';
        }

        setGLAttrib( SDL_GL_RED_SIZE, 5 );
        setGLAttrib( SDL_GL_GREEN_SIZE, 5 );
        setGLAttrib( SDL_GL_BLUE_SIZE, 5 );
        setGLAttrib( SDL_GL_DEPTH_SIZE, 16 );
        setGLAttrib( SDL_GL_DOUBLEBUFFER, 1 );

        windows[0] = myztic.display.Window.create({name: "Myztic Engine", flags: SDL_WINDOW_OPENGL | SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE});
        //glContexts[0] = SDL.GL_CreateContext(windows[0]);
        final gladResult:Int = Glad.gladLoadGLLoader(untyped __cpp__('(GLADloadproc)SDL_GL_GetProcAddress'));
        if (gladResult == 0)
            throw 'Failed to initialize GLAD! Most likely outdated OpenGL Version, Required: OpenGL 3.3, ERROR CODE: $gladResult';
        
        var glV:String;
        try { glV = GLH.getString(OpenGL.GL_VERSION); }
        catch(e) { throw 'Could not automatically get current OpenGL version. Please check manually. (GL 3.3 is required) [ERROR::$e]'; }

        //i am actually so sorry
        if((Glad.glVersion.major == 3 && Glad.glVersion.minor != 3) || (Glad.glVersion.major != 4)) 
            throw 'OpenGL version 3.3 is not supported on this device.
            \nCheck if your drivers are installed properly and if your GPU supports GL 3.3.
            \nRegistered Version: $glV';
        
        opengl.OpenGL.glViewport(0, 0, getMainWindow().width, getMainWindow().height); // Set Viewport for first time init
        
        trace("RUNNING ON OPENGL VERSION: " + glV);
        trace("GLSL VERSION IS: " + GLH.getString(OpenGL.GL_SHADING_LANGUAGE_VERSION));
        
        trace('Current context is made context?? - ${SDL.GL_GetCurrentContext() == windows[0].glContext}');
        trace('Vendor: ${GLH.getString(OpenGL.GL_VENDOR)}');
    }
}