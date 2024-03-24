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
import glm.Mat4;
import glm.GLM;
import glm.Mat2;
import glm.Vec3;

import myztic.graphics.backend.VBO;
import myztic.graphics.backend.VAO;
import myztic.graphics.backend.EBO;
import myztic.graphics.backend.Shader;
import myztic.graphics.backend.ShaderInputLayout;
import myztic.graphics.backend.Texture2D;
import myztic.helpers.StarArray;
import myztic.Application;
import myztic.helpers.ErrorHandler.checkGLError;
import myztic.display.DisplayHandler;
import myztic.helpers.ErrorHandler;
import myztic.display.Window as MyzWin;
import InitScene;

import cpp.Float32;

using cpp.Native;

// todo: BIG :: MOVE UPDATING AND FPS INTO APPLICATION!!!
// future: use sprites ionstead of backend graphics
@:buildXml('<include name="../builder.xml" />')
@:cppInclude('glm.hpp')
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
    static var myzWin:MyzWin;

    static var glc:sdl.GLContext;

    static var shaderProgram:ShaderProgram;
    //static var vao:VAO;
    static var ebo:EBO;
    static var vbo:VBO;
    static var inputLayout:ShaderInputLayout;
    static var texture:Texture2D;
    static var trans:Mat4;

    static function main() {
        fps = 60;

        // ! MOST RECENTLY CREATED WINDOW IS CURRENT GL WINDOW???? MAYBE THATS THE KICKER??? it was :(
        final iSc = new InitScene();
        Application.initMyztic(iSc);
        myzWin = Application.focusedWindow();
        window = myzWin.backend.handle;

        final win2 = MyzWin.create({name: "Window Test 1", init_scene: iSc, flags: SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE});
        final win3 = MyzWin.create({name: "Window Test 2", init_scene: iSc, init_pos: [25, 25], flags: SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE});
        ErrorHandler.checkSDLError(SDL.GL_MakeCurrent(win2.backend.handle, myzWin.backend.glContext));
        ErrorHandler.checkSDLError(SDL.GL_MakeCurrent(win3.backend.handle, myzWin.backend.glContext));

        trace(DisplayHandler.monitors);
        trace(Application.windows);

        inline function checkCurrentWindow() {
            var cur = SDL.GL_GetCurrentWindow();
            trace("MyzWin currently is: " + Application.windows[SDL.getWindowID(cur)]);
        }
        checkCurrentWindow();
        ErrorHandler.checkSDLError(SDL.GL_MakeCurrent(myzWin.backend.handle, myzWin.backend.glContext));
        checkCurrentWindow();

        ///*
        
        var compiled = SDL.VERSION();
        var linked = SDL.getVersion();
        trace("Versions:");
        trace('    - We compiled against SDL version ${compiled.major}.${compiled.minor}.${compiled.patch} ...');
        trace('    - And linked against SDL version ${linked.major}.${linked.minor}.${linked.patch}');

        final maxVtxAttribs:cpp.Int32 = 0;
        GL.glGetIntegerv(GL.GL_MAX_VERTEX_ATTRIBS, maxVtxAttribs.addressOf());
        trace("Max available vertex attribs (vertex shader input): " + maxVtxAttribs);
        myztic.helpers.ErrorHandler.checkGLError();

        //trans = new Mat4();
        //trans = Mat4.identity(trans);
        //trans = GLM.rotate(glm.Quat.axisAngle(new Vec3(0, 0, 1), 90, new glm.Quat()), trans);
        //trans = GLM.scale(new Vec3(0.5, 0.5, 0.5), trans);

        var vertices:StarArray<GLfloat> = new StarArray<GLfloat>(36);
        vertices.fillFrom(0, 
            [
                //vtx is position, color, texcoord
                0.5, 0.5, 0.0, 
                1.0, 0.0, 0.0,
                1.0, 0.0,

                0.5, -0.5, 0.0,
                0.0, 1.0, 0.0,
                1.0, 1.0, 

                -0.5, -0.5, 0.0,
                0.0, 0.0, 1.0,
                0.0, 1.0,

                -0.5, 0.5, 0.0,
                1.0, 0.0, 0.0,
                0.0, 0.0
            ]
        );
        
        vertices.data_index = 0;
        
        var indices:StarArray<cpp.UInt32> = new StarArray<cpp.UInt32>(6);
        indices.fillFrom(0, [0, 1, 3, 1, 2, 3]);
        indices.data_index = 0;

        //vao = VAO.make();
        ebo = EBO.make();
        vbo = VBO.make();

        //vao.bindVertexArray();

        vbo.bindVertexBuffer();
        vbo.changeVertexBufferData(vertices, GL.GL_STATIC_DRAW); // todo: vertices StarArray

        texture = Texture2D.fromFile("Yanni.png");

        inputLayout = ShaderInputLayout.createInputLayout(ShaderInputLayout.createLayoutDescription([ShaderInputLayout.POSITION, ShaderInputLayout.COLOR, ShaderInputLayout.TEXCOORD]));
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

        shaderProgram.getUniformLocation("transform");

        vertexShader.deleteShader();
        fragShader.deleteShader();
        GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_FILL);

        SDL.stopTextInput();

        cpp.vm.Gc.run(true);
        
        startAppLoop();

        //vao.deleteArrayObject();
        VBO.unbindBuffer();
        VAO.unbindGLVertexArray();
        EBO.unbindBuffer();
        Texture2D.unbindTexture();
        GL.glUseProgram(0);
        inputLayout.disableAllAttribs();

        vbo.deleteBuffer();
        ebo.deleteBuffer();
        texture.deleteTexture();
        inputLayout.deleteInputLayout();
        shaderProgram.deleteProgram();

        // App Exit
        SDL.destroyWindow(window);
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
                    case Keycodes.key_s:
                        final randNum = Std.random(3) + 1;
                        final randWin = Application.windows[randNum];
                        ErrorHandler.checkSDLError(SDL.GL_MakeCurrent(randWin.backend.handle, Application.windows[1].backend.glContext));
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
        //enable alpha shit?
        GL.glEnable(GL.GL_BLEND);
        GL.glBlendFunc(GL.GL_ONE, GL.GL_ONE_MINUS_SRC_ALPHA);

        GL.glClearColor(0, 0, 0.2, 1);
        GL.glClear(GL.GL_COLOR_BUFFER_BIT);

        shaderProgram.useProgram();

        //shaderProgram.modifyUniformVector3([1.0, (Math.sin(Timer.stamp()) / 2) + 0.5, 0.3], shaderProgram.uniforms.get("vertCol"));
        shaderProgram.uniformMatrix4fv(/*trans,*/ shaderProgram.getUniformLocation("transform"));
        //vao.bindVertexArray();
        texture.bindTexture();
        inputLayout.bindInputLayout();

        GL.glDrawElements(GL.GL_TRIANGLES, 6, GL.GL_UNSIGNED_INT, 0);

        VAO.unbindGLVertexArray();

        GL.glDisable(GL.GL_BLEND);

        SDL.GL_SwapWindow(SDL.GL_GetCurrentWindow());
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