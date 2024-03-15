package;

import myztic.display.DisplayHandler;
import InitScene;
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
import myztic.graphics.backend.ShaderInputLayout;

import cpp.Float32;

using cpp.Native;

// todo: BIG :: MOVE UPDATING AND FPS INTO APPLICATION!!!
// future: use sprites ionstead of backend graphics
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
    static var myzWin:myztic.display.Window;

    static var glc:sdl.GLContext;

    static var shaderProgram:ShaderProgram;
    //static var vao:VAO;
    static var ebo:EBO;
    static var inputLayout:ShaderInputLayout;

    static function main() {
        fps = 60;

        Application.initMyztic(new InitScene());
        myzWin = Application.focusedWindow();
        window = myzWin.backend.handle;
        ///*
        
        var compiled = SDL.VERSION();
        var linked = SDL.getVersion();
        trace("Versions:");
        trace('    - We compiled against SDL version ${compiled.major}.${compiled.minor}.${compiled.patch} ...');
        trace('    - And linked against SDL version ${linked.major}.${linked.minor}.${linked.patch}');
        // */

        final maxVtxAttribs:cpp.Int32 = 0;
        GL.glGetIntegerv(GL.GL_MAX_VERTEX_ATTRIBS, maxVtxAttribs.addressOf());
        trace("Max available vertex attribs (vertex shader input): " + maxVtxAttribs);
        myztic.helpers.ErrorHandler.checkGLError();

        var vertices:StarArray<GLfloat> = new StarArray<GLfloat>(24);
        vertices.fillFrom(0, 
            [
                //vtx is position, color
                0.5, 0.5, 0.0, 
                1.0, 0.0, 0.0,

                0.5, -0.5, 0.0,
                0.0, 1.0, 0.0,

                -0.5, -0.5, 0.0,
                0.0, 0.0, 1.0,

                -0.5, 0.5, 0.0,
                1.0, 0.0, 0.0
            ]
        );
        
        vertices.data_index = 0;
        
        var indices:StarArray<cpp.UInt32> = new StarArray<cpp.UInt32>(6);
        indices.fillFrom(0, [0, 1, 3, 1, 2, 3]);
        indices.data_index = 0;

        //vao = VAO.make();
        ebo = EBO.make();
        final vertexBuffer:VBO = VBO.make();

        //vao.bindVertexArray();

        vertexBuffer.bindVertexBuffer();
        vertexBuffer.changeVertexBufferData(vertices, GL.GL_STATIC_DRAW); // todo: vertices StarArray

        inputLayout = ShaderInputLayout.createInputLayout(ShaderInputLayout.createLayoutDescription([ShaderInputLayout.POSITION, ShaderInputLayout.COLOR]));
        inputLayout.enableAllAttribs();

        ebo.bind();
        ebo.changeElementBufferData(indices);

        VBO.unbindBuffer();

        var vertexShader:Shader = new Shader(GL.GL_VERTEX_SHADER, "VS.glsl");
        var fragShader:Shader = new Shader(GL.GL_FRAGMENT_SHADER, "FS.glsl");

        shaderProgram = new ShaderProgram();
        shaderProgram.attachShader(vertexShader);
        shaderProgram.attachShader(fragShader);

        shaderProgram.link();

        shaderProgram.useProgram();

        //shaderProgram.getUniformLocation("vertCol");

        vertexShader.deleteShader();
        fragShader.deleteShader();
        GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_FILL);

        // GL.glViewport(0, 0, cast Display.getCurrentMonitor().width / 2, cast Display.getCurrentMonitor().height / 2); // Set Viewport for first time init

        SDL.stopTextInput();
        
        startAppLoop();

        //vao.deleteArrayObject();
        inputLayout.deleteInputLayout();
        shaderProgram.deleteProgram();

        // App Exit
        SDL.destroyWindow(window);
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

        //shaderProgram.modifyUniformVector3([1.0, (Math.sin(Timer.stamp()) / 2) + 0.5, 0.3], shaderProgram.uniforms.get("vertCol"));
        //vao.bindVertexArray();
        inputLayout.bindInputLayout();

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
}