package;

import haxe.Template;
import haxe.ds.Vector;
import haxe.io.BytesOutput;
import haxe.io.BytesBuffer;
import haxe.io.BytesData;
import haxe.io.Bytes;
import haxe.Timer;
import haxe.io.BytesInput;

import sdl.Keycodes;
import sdl.Event;
import sdl.SDL;
import sdl.Surface;
import sdl.MessageBox;
import sdl.Window;
import sdl.Surface;
import sdl.SDL.GL_SetAttribute as setGLAttrib;

import opengl.OpenGL as GL;
import opengl.OpenGL.GLuint;
import opengl.OpenGL.GLboolean;
import opengl.OpenGL.GLfloat;
import opengl.OpenGL.GLuintPointer;
import opengl.OpenGL.GLintPointer;
import glad.Glad;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;

import myztic.graphics.backend.VBO;
import myztic.graphics.backend.VAO;
import myztic.graphics.backend.EBO;
import myztic.graphics.backend.Shader;
import myztic.graphics.backend.ShaderInputLayout;
import myztic.graphics.backend.Texture2D;
import myztic.graphics.Camera;
import myztic.helpers.StarArray;
import myztic.Application;
import myztic.helpers.ErrorHandler.checkGLError;
import myztic.display.DisplayHandler;
import myztic.helpers.ErrorHandler;
import myztic.display.Window as MyzWin;
import myztic.util.Math.radians;
import InitScene;

import cpp.Float32;

using cpp.Native;

// todo: BIG :: MOVE UPDATING AND FPS INTO APPLICATION!!!
// future: use sprites ionstead of backend graphics
class Main {
    public static var fps(default, set):Int = 30; // Set in Main!!
    public static var camera:Camera;
    
    static var usedFps:Int = 0;
    static var _curFPSCnt:Int = 0;
    
    /**
     * Number of seconds between each frame.
     */
    static var frameDurMS:Float = 0;
    static var currentTime:Float;
    static var accumulator:Float;

    static var shouldClose:Bool = false;

    static var initScene:InitScene;

    static function main() {
        fps = 60;

        initScene = new InitScene();
        Application.initMyztic(initScene);

        SDL.stopTextInput();

        cpp.vm.Gc.run(true);
        
        camera = new Camera();
        
        startAppLoop();

        // App Exit
        cpp.vm.Gc.run(true);
        SDL.quit();

        Sys.exit(0);
    }

    /**
     * Fires an SDL Event of the given type.
     * @param type Type of SDL Event.
     */
    inline static function fireSDLEvent(eType:SDLEventType):Void {
        untyped __cpp__('
            SDL_Event event;
            event.type = {0};

            SDL_PushEvent (&event);
        ', eType);
    }

    
    static var textInput = "";
    static function startAppLoop():Void {
        var newTime = 0.0;
        var frameTime = newTime - currentTime;
        
        while(!shouldClose) { 
            newTime = Timer.stamp();
            frameTime = newTime - currentTime;

            currentTime = newTime;
            accumulator = if (frameTime > 0.25) accumulator + 0.25 else accumulator + frameTime;

            while (accumulator >= frameDurMS) {
                handleSDLEvents();
                globalUpdate(frameDurMS, frameDurMS/*, frameTime*/); // TODO: make this use a time accurate variable to properly show fps and not some "fake value"

                accumulator -= frameDurMS;
                // frameTime = 0; // TODO: calculate time the frame took and throw it onto the frameTime!!!! 
            }
            
            SDL.delay(1); // If we dont do this our CPU usage turns insanely high
        }
    }

    private static inline var MOVE_SPEED:cpp.Float32 = 2.5;

    #if !debug inline #end static function handleSDLEvents():Void {
        var continueEventSearch = SDL.hasAnEvent();
        while(continueEventSearch) {
            var e = SDL.pollEvent();
            
            switch(e.type) {
                case SDL_QUIT: 
                    // If handleQuitReq returns true we are actually quitting, otherwise we're not!! Useful for "Save / Cancel" operations
                    trace("quit req!");
                    continueEventSearch = !(shouldClose = handleQuitReq()) && SDL.hasAnEvent();

                case SDL_WINDOWEVENT: 
                switch(e.window.event) {
                    case SDL_WINDOWEVENT_RESIZED:
                        ErrorHandler.checkSDLError(SDL.GL_MakeCurrent(Application.windows[e.window.windowID].backend.handle, Application.windows[1].backend.glContext)); 
                        // switched to window thats resized
                        initScene.projection = glm.GLM.perspective(45, e.window.data1/e.window.data2, 0.1, 100.0);
                        GL.glViewport(0, 0, e.window.data1, e.window.data2);
                    
                    case SDL_WINDOWEVENT_CLOSE: 
                        if(Application.nWindows == 1) { // todo: window close events (generally window events lol), handle like quit ret?
                            // window.onCloseReq(reason/context???)
                            continue; // SDL_QUIT is automatically called right afterwards
                        }
                        Application.windows[e.window.windowID].destroy();
                    default:
                }
                case SDL_MOUSEBUTTONDOWN: // Mouse Click
                switch(e.button.button) { // Lets find out what Mouse Part clicked!!
                    case SDL_BUTTON_LEFT: 
                        trace("Currently set FPS: " + fps);
                        trace("Currently used FPS: " + usedFps);
                        trace("FPS frame delay Seconds: " + frameDurMS);
                        trace("---------------------------------\n");

                    case SDL_BUTTON_RIGHT:
                        final inputActive = SDL.isTextInputActive();

                        if(!inputActive) SDL.startTextInput();
                        else SDL.stopTextInput();
                        SDL.showSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, 'INFO', 'TOGGLED TEXT INPUT: ${!inputActive}', initScene.window);
                        textInput = '';
                    default: 
                        final newFps = Std.parseInt(textInput);
                        if(newFps != null && newFps > 0) {
                            SDL.showSimpleMessageBox(SDL_MESSAGEBOX_WARNING, 'INFO', 'FPS set from $fps to $newFps', initScene.window);
                            fps = newFps;
                        }
                        else SDL.showSimpleMessageBox(SDL_MESSAGEBOX_WARNING, 'WARNING', 'Could not set FPS to input data: $textInput', initScene.window);
                        
                        textInput = '';
                }
                case SDL_KEYDOWN:
                switch(e.key.keysym.sym) {
                    case Keycodes.backspace:         
                        reqExit();
                    /*case Keycodes.key_s:
                        final randNum = Std.random(3) + 1;
                        final randWin = Application.windows[randNum];
                        ErrorHandler.checkSDLError(SDL.GL_MakeCurrent(randWin.backend.handle, Application.windows[1].backend.glContext));*/
                    case Keycodes.insert:
                        //freecam mode
                        camera.free = true;
                    case Keycodes.key_w:
                        if (camera.free)
                            camera.camPos.plusEqual(camera.camLook.multiplyScalar(MOVE_SPEED * frameDurMS));
                    case Keycodes.key_s:
                        if (camera.free)
                            camera.camPos.minusEqual(camera.camLook.multiplyScalar(MOVE_SPEED * frameDurMS));
                    case Keycodes.key_a:
                        if (camera.free)
                            camera.camPos.minusEqual(GLM.normalize(GLM.cross(camera.camLook, Camera.UP)).multiplyScalar(MOVE_SPEED * frameDurMS));
                    case Keycodes.key_d:
                        if (camera.free)
                            camera.camPos.plusEqual(GLM.normalize(GLM.cross(camera.camLook, Camera.UP)).multiplyScalar(MOVE_SPEED * frameDurMS));
                    default:
                }

                case SDL_TEXTINPUT:
                    textInput += e.text.text;
                default:
            }

            continueEventSearch = SDL.hasAnEvent();
        }
    }

    // Requests an exit operation
    inline static function reqExit() fireSDLEvent(SDL_QUIT);

    inline static function logWarning(warning:Dynamic) {
        trace('Warning: $warning (Registered at: ${Date.now()})');
    } 

    static var _fpsSecCnt:Float = 0;
    #if !debug inline #end static function globalUpdate(dt:Float, lastAccumTime:Float):Void { 
        update(dt);
        // draw here!
        initScene.render();

        _curFPSCnt++;
        _fpsSecCnt += lastAccumTime;
        if(_fpsSecCnt >= 1) {
            usedFps = _curFPSCnt;
            _fpsSecCnt = _curFPSCnt = 0; // Reset FPS 
        }
    }

    static final msgBoxContinue = MessageBox.makeCallbackButton('Continue', () -> {});
    static final msgBoxQuit = MessageBox.makeCallbackButton('Quit', () -> { mayQuit = true; });
    static var mayQuit:Bool = false;
    dynamic static function handleQuitReq():Bool {
        MessageBox.showCallbacksMessageBox(
            'Quit requested',
            'Would you like to continue or quit?',
            initScene.window,
            SDL_MessageBoxFlags.SDL_MESSAGEBOX_WARNING,
            [msgBoxContinue, msgBoxQuit]
        );

        return mayQuit;
    }

    // static var red = 0.1;
    // static var blue = 0.1;
    /**
     * Update Loop
     * @param dt Time elapsed since last frame in MS
     */
    static function update(dt:Float) {
        // red = Math.random();
        // blue = Math.random();

        // SDL.setHint(SDL_HINT_RENDER_VSYNC, 'true');
    }

    static function set_fps(st:Int):Int { 
        // final oldFps = fps;
        frameDurMS = 1 / st;
        usedFps = st;
        return fps = st; 
    }
}