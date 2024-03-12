package;

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
import sdl.Surface;
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

import myztic.graphics.backend.VBO;
import myztic.graphics.backend.VAO;
import myztic.graphics.backend.EBO;
import myztic.graphics.backend.Shader;
import myztic.helpers.StarArray;
import myztic.display.DisplayHandler as Display;
import myztic.Application;
import myztic.helpers.ErrorHandler;

import cpp.Float32;

using cpp.Native;

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

    static var shaderProgram:ShaderProgram;
    static var vao:VAO;
    static var ebo:EBO;

    static function main() {
        fps = 60;

        Application.initMyztic();
        window = Application.getMainWindow().handle;

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

        final maxVtxAttribs:cpp.Int32 = 0;
        GL.glGetIntegerv(GL.GL_MAX_VERTEX_ATTRIBS, maxVtxAttribs.addressOf());
        trace("Max available vertex attribs (vertex shader input): " + maxVtxAttribs);

        var vertices:StarArray<GLfloat> = new StarArray<GLfloat>(12);
        vertices.fillFrom(0, 
            [0.5,  0.5, 0.0,
            0.5, -0.5, 0.0,
            -0.5, -0.5, 0.0,
            -0.5,  0.5, 0.0]
        );
        
        vertices.data_index = 0;
        
        var indices:StarArray<cpp.UInt32> = new StarArray<cpp.UInt32>(6);
        indices.fillFrom(0, [0, 1, 3, 1, 2, 3]);
        indices.data_index = 0;

        vao = VAO.make();
        ebo = EBO.make();
        final vertexBuffer:VBO = VBO.make();
       
        vao.bindVertexArray();

        vertexBuffer.bindVertexBuffer();
        vertexBuffer.changeVertexBufferData(vertices, GL.GL_STATIC_DRAW); // todo: vertices StarArray

        ebo.bind();
        ebo.changeElementBufferData(indices);

        GL.glVertexAttribPointer(0, 3, GL.GL_FLOAT, false, 3 * Float32.sizeof(), 0);
        GL.glEnableVertexAttribArray(0);

        var vertexShader:Shader = new Shader(GL.GL_VERTEX_SHADER, "VS.glsl");
        var fragShader:Shader = new Shader(GL.GL_FRAGMENT_SHADER, "FS.glsl");

        shaderProgram = new ShaderProgram();
        shaderProgram.attachShader(vertexShader);
        shaderProgram.attachShader(fragShader);

        shaderProgram.link();

        shaderProgram.useProgram();

        shaderProgram.getUniformLocation("vertCol");

        vertexShader.deleteShader();
        fragShader.deleteShader();
        GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_FILL);

        // GL.glViewport(0, 0, cast Display.currentMode.w / 2, cast Display.currentMode.h / 2); // Set Viewport for first time init

        SDL.stopTextInput();
        
        startAppLoop();

        vao.deleteArrayObject();
        shaderProgram.deleteProgram();

        // Exiting our application from here on out, we can clean up everything!!
        SDL.destroyWindow(window);
        // SDL.destroyRenderer(state.renderer);
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
        GL.glClearColor(0, 0, 0.2, 1);
        GL.glClear(GL.GL_COLOR_BUFFER_BIT);

        shaderProgram.useProgram();

        shaderProgram.modifyUniformVector3([1.0, (Math.sin(Timer.stamp()) / 2) + 0.5, 0.3], shaderProgram.uniforms.get("vertCol"));
        vao.bindVertexArray();

        GL.glDrawElements(GL.GL_TRIANGLES, 6, GL.GL_UNSIGNED_INT, 0);

        VAO.unbindGLVertexArray();

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
}