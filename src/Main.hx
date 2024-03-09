package;

import cpp.Pointer;
import haxe.Template;
import haxe.ds.Vector;
import haxe.io.BytesOutput;
import haxe.io.BytesBuffer;
import haxe.io.BytesData;
import haxe.io.Bytes;
import haxe.Timer;

import sdl.Keycodes;
import sdl.Event;
import sdl.SDL;

import sdl.MessageBox;
import sdl.Window;
import sdl.SDL.GL_SetAttribute as setGLAttrib;

import opengl.OpenGL as GL;
import opengl.OpenGL.GLuint;
import opengl.OpenGL.GLboolean;
import opengl.OpenGL.GLfloat;
import opengl.OpenGL.GLuintPointer;
import opengl.OpenGL.GLintPointer;
import opengl.VoidPointer;
import opengl.StringPointer;
import glad.Glad;

import graphics.oglh.GLH;
import graphics.oglh.VBO;

import myztic.util.StarArray;

import cpph.Tools;
import cpp.Float32;

using cpp.Native;

// Interesting todo:
// GL Integration

@:headerInclude('iostream')
class Main {
    public static var fps(default, set):Int = 30; // Set in Main!!
    static var usedFps:Int = 0;
    static var _curFPSCnt:Int = 0;
    
    /**
     * Number of seconds between each frame.
     */
    static var frameDurMS:Float = 0;
    static var currentTime:Float;
    static var accumulator:Float;

    static var shouldClose:Bool = false;
    static var window:Window;

    static var glc:sdl.GLContext;

    static var shaderProgram:GLuint;
    static var vertexArrayObject:GLuint;

    static function main() {
        fps = 60;

        var str:StarArray<cpp.Int32> = new StarArray<cpp.Int32>(3);
        str.setCurrent(2);
        str.set(1, 4);
        str.set(2, 6);
        trace(str.size);
        trace(str.getCurrent());
        trace(str.get(0));

        // str.process();

        if(SDL.init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_GAMECONTROLLER | SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC) != 0) {
            throw 'Error initializing SDL subsystems: ${SDL.getError()}';
        }


        /*
        trace('Displays:');
        var num_displays = SDL.getNumVideoDisplays();
        for(display_index in 0 ... num_displays) {
            var num_modes = SDL.getNumDisplayModes(display_index);
            var name = SDL.getDisplayName(display_index);
            trace('\tDisplay $display_index: $name');
            var desktop_mode = SDL.getDesktopDisplayMode(display_index);
            trace('\t Desktop Mode: ${desktop_mode.w}x${desktop_mode.h} @ ${desktop_mode.refresh_rate}Hz format:${pixel_format_to_string(desktop_mode.format)}');
            var current_mode = SDL.getCurrentDisplayMode(display_index);
            trace('\t Current Mode: ${current_mode.w}x${current_mode.h} @ ${current_mode.refresh_rate}Hz format:${pixel_format_to_string(current_mode.format)}');
            for(display_mode in 0 ... num_modes) {
                var mode = SDL.getDisplayMode(display_index, display_mode);
                trace('\t\t mode:$display_mode ${mode.w}x${mode.h} @ ${mode.refresh_rate}Hz format:${pixel_format_to_string(mode.format)}');
            }
        }
        
        var compiled = SDL.VERSION();
        var linked = SDL.getVersion();
        trace("Versions:");
        trace('    - We compiled against SDL version ${compiled.major}.${compiled.minor}.${compiled.patch} ...');
        trace('    - And linked against SDL version ${linked.major}.${linked.minor}.${linked.patch}');
        // */

        setGLAttrib( SDL_GL_RED_SIZE, 5 );
        setGLAttrib( SDL_GL_GREEN_SIZE, 5 );
        setGLAttrib( SDL_GL_BLUE_SIZE, 5 );
        setGLAttrib( SDL_GL_DEPTH_SIZE, 16 );
        setGLAttrib( SDL_GL_DOUBLEBUFFER, 1 );

        var displayMode = SDL.getCurrentDisplayMode(0);
        final width:Int = cast displayMode.w / 2;
        final height:Int = cast displayMode.h / 2;

        window = myztic.display.Window.create({name: "SDL TEST", flags: SDL_WINDOW_OPENGL | SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE}).handle;

        trace(SDL.getWindowDisplayIndex(window));


        glc = SDL.GL_CreateContext(window); // Cant check if glc is null, gotta depend on contex tsetting providing work
        final cRes = SDL.GL_MakeCurrent(window, glc);
        if(cRes != 0) throw 'Error making context current of window ${SDL.getWindowID(window)}! - ${SDL.getError()}';
        final gladResult:Int = Glad.gladLoadGLLoader(untyped __cpp__('(GLADloadproc)SDL_GL_GetProcAddress')); // Its important we initialize GLAD AFTER making our context
        if(gladResult != 1) throw 'Failed to initialize GLAD! Most likely outdated OpenGL Version, Required: OpenGL 3.3, ERROR CODE: $gladResult';
        
        var glV:String;
        try { glV = GLH.getString(GL.GL_VERSION); }
        catch(e) { throw 'Could not automatically get current OpenGL version. Please check manually. (GL 3.3 is required) [ERROR::$e]'; }

        //i am actually so sorry
        if((Glad.glVersion.major == 3 && Glad.glVersion.minor != 3) || (Glad.glVersion.major != 4)) 
            throw 'OpenGL version 3.3 is not supported on this device.
            \nCheck if your drivers are installed properly and if your GPU supports GL 3.3.
            \nRegistered Version: $glV';

        trace("RUNNING ON OPENGL VERSION: " + glV);
        trace("GLSL VERSION IS: " + GLH.getString(GL.GL_SHADING_LANGUAGE_VERSION));

        trace('Current context is made context?? - ${SDL.GL_GetCurrentContext() == glc}');
        trace('Vendor: ${GLH.getString(GL.GL_VENDOR)}');

        final vertices:Array<GLfloat> = [
            -0.5, -0.5, 0.0,
            0.5, -0.5, 0.0,
            0.0,  0.5, 0.0
        ];

        GL.glGenVertexArrays(1,vertexArrayObject.addressOf());
        final vertexBuffer:VBO = VBO.make();
       
        GL.glBindVertexArray(vertexArrayObject);

        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, vertexBuffer.handle);

        GL.glBufferData(GL.GL_ARRAY_BUFFER, GLfloat.sizeof() * vertices.length, Tools.get_void_ptr_from_array(vertices), GL.GL_STATIC_DRAW);
        trace(GL.glGetError());

        GL.glVertexAttribPointer(0, 3, GL.GL_FLOAT, false, 3 * GLfloat.sizeof(), 0);
        GL.glEnableVertexAttribArray(0);

        var vs:String = "#version 330 core\n
        layout (location = 0) in vec3 aPos;\n
        
        void main()\n
        {\n
            gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n
        }\n";

        var vertexShader:GLuint = GL.glCreateShader(GL.GL_VERTEX_SHADER);
       
        GL.glShaderSource(vertexShader, 1, StringPointer.fromString(vs), null);
        GL.glCompileShader(vertexShader);

        //get info
        var success:Int = -65694;
        GL.glGetShaderiv(vertexShader, GL.GL_COMPILE_STATUS, GLintPointer.fromInteger(success));
        trace(success);

        var fs:String = "#version 330 core\n
        out vec4 FragColor;\n
        
        void main()\n
        {\n
            FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n
        } \n";

        var fragShader:GLuint = GL.glCreateShader(GL.GL_FRAGMENT_SHADER);

        GL.glShaderSource(fragShader, 1, StringPointer.fromString(fs), null);
        GL.glCompileShader(fragShader);

        GL.glGetShaderiv(fragShader, GL.GL_COMPILE_STATUS, GLintPointer.fromInteger(success));
        trace(success);

        shaderProgram = GL.glCreateProgram();

        GL.glAttachShader(shaderProgram, vertexShader);
        GL.glAttachShader(shaderProgram, fragShader);
        GL.glLinkProgram(shaderProgram);

        GL.glDeleteShader(vertexShader);
        GL.glDeleteShader(fragShader);

        GL.glViewport(0, 0, width, height); // Set Viewport for first time init

        SDL.stopTextInput();
        
        startAppLoop();

        // Exiting our application from here on out, we can clean up everything!!
        SDL.destroyWindow(window);
        // SDL.destroyRenderer(state.renderer);
        SDL.quit();
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
        while(!shouldClose) { 
            final newTime = Timer.stamp();
            var frameTime = newTime - currentTime;

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

    inline static function handleSDLEvents():Void {
        var continueEventSearch = SDL.hasAnEvent();
        while(continueEventSearch) {
            var e = SDL.pollEvent();
            
            switch(e.type) {
                case SDL_QUIT: 
                    // If handleQuitReq returns true we are actually quitting, otherwise we're not!! Useful for "Save / Cancel" operations
                    continueEventSearch = !(shouldClose = handleQuitReq()) && SDL.hasAnEvent();

                case SDL_WINDOWEVENT: 
                switch(e.window.event) {
                    case SDL_WINDOWEVENT_RESIZED:
                        GL.glViewport(0, 0, e.window.data1, e.window.data2);
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
                        SDL.showSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, 'INFO', 'TOGGLED TEXT INPUT: ${!inputActive}', window);
                        textInput = '';
                    default: 
                        final newFps = Std.parseInt(textInput);
                        if(newFps != null && newFps > 0) {
                            SDL.showSimpleMessageBox(SDL_MESSAGEBOX_WARNING, 'INFO', 'FPS set from $fps to $newFps', window);
                            fps = newFps;
                        }
                        else SDL.showSimpleMessageBox(SDL_MESSAGEBOX_WARNING, 'WARNING', 'Could not set FPS to input data: $textInput', window);
                        
                        textInput = '';
                }
                case SDL_KEYDOWN:
                switch(e.key.keysym.sym) {
                    case Keycodes.backspace:         
                        reqExit();
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
        render();

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
            window,
            SDL_MessageBoxFlags.SDL_MESSAGEBOX_WARNING,
            [msgBoxContinue, msgBoxQuit]
        );

        return mayQuit;
    }

    static function render():Void {
        GL.glClearColor(red, 1, blue, 1);
        GL.glClear(GL.GL_COLOR_BUFFER_BIT);

        GL.glUseProgram(shaderProgram);
        GL.glBindVertexArray(vertexArrayObject);
        GL.glDrawArrays(GL.GL_TRIANGLES, 0, 3);

        SDL.GL_SwapWindow(window);
    }

    static var red = 0.1;
    static var blue = 0.1;
    /**
     * Update Loop
     * @param dt Time elapsed since last frame in MS
     */
    static function update(dt:Float) {
        red = Math.random();
        blue = Math.random();

        // SDL.setHint(SDL_HINT_RENDER_VSYNC, 'true');
    }

    static function set_fps(st:Int):Int { 
        // final oldFps = fps;
        frameDurMS = 1 / st;
        usedFps = st;
        return fps = st; 
    }


    static function pixel_format_to_string(format:SDLPixelFormat) {
        return switch(format) {
            case SDL_PIXELFORMAT_UNKNOWN     :'UNKNOWN';
            case SDL_PIXELFORMAT_INDEX1LSB   :'INDEX1LSB';
            case SDL_PIXELFORMAT_INDEX1MSB   :'INDEX1MSB';
            case SDL_PIXELFORMAT_INDEX4LSB   :'INDEX4LSB';
            case SDL_PIXELFORMAT_INDEX4MSB   :'INDEX4MSB';
            case SDL_PIXELFORMAT_INDEX8      :'INDEX8';
            case SDL_PIXELFORMAT_RGB332      :'RGB332';
            case SDL_PIXELFORMAT_RGB444      :'RGB444';
            case SDL_PIXELFORMAT_RGB555      :'RGB555';
            case SDL_PIXELFORMAT_BGR555      :'BGR555';
            case SDL_PIXELFORMAT_ARGB4444    :'ARGB4444';
            case SDL_PIXELFORMAT_RGBA4444    :'RGBA4444';
            case SDL_PIXELFORMAT_ABGR4444    :'ABGR4444';
            case SDL_PIXELFORMAT_BGRA4444    :'BGRA4444';
            case SDL_PIXELFORMAT_ARGB1555    :'ARGB1555';
            case SDL_PIXELFORMAT_RGBA5551    :'RGBA5551';
            case SDL_PIXELFORMAT_ABGR1555    :'ABGR1555';
            case SDL_PIXELFORMAT_BGRA5551    :'BGRA5551';
            case SDL_PIXELFORMAT_RGB565      :'RGB565';
            case SDL_PIXELFORMAT_BGR565      :'BGR565';
            case SDL_PIXELFORMAT_RGB24       :'RGB24';
            case SDL_PIXELFORMAT_BGR24       :'BGR24';
            case SDL_PIXELFORMAT_RGB888      :'RGB888';
            case SDL_PIXELFORMAT_RGBX8888    :'RGBX8888';
            case SDL_PIXELFORMAT_BGR888      :'BGR888';
            case SDL_PIXELFORMAT_BGRX8888    :'BGRX8888';
            case SDL_PIXELFORMAT_ARGB8888    :'ARGB8888';
            case SDL_PIXELFORMAT_RGBA8888    :'RGBA8888';
            case SDL_PIXELFORMAT_ABGR8888    :'ABGR8888';
            case SDL_PIXELFORMAT_BGRA8888    :'BGRA8888';
            case SDL_PIXELFORMAT_ARGB2101010 :'ARGB2101010';
            case SDL_PIXELFORMAT_YV12        :'YV12';
            case SDL_PIXELFORMAT_IYUV        :'IYUV';
            case SDL_PIXELFORMAT_YUY2        :'YUY2';
            case SDL_PIXELFORMAT_UYVY        :'UYVY';
            case SDL_PIXELFORMAT_YVYU        :'YVYU';
            case SDL_PIXELFORMAT_NV12        :'NV12';
            case SDL_PIXELFORMAT_NV21        :'NV21';
        }
    }

    static function drawTriangle() {
        // GL.glBufferData(GL.GL_ARRAY_BUFFER, Native.sizeof(data), vertices, GL.GL_STATIC_DRAW);

    }

}