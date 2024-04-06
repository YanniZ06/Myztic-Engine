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
import sdl.Window as SDLWin;
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
import myztic.helpers.StarArray;
import myztic.Application;
import myztic.helpers.ErrorHandler.checkGLError;
import myztic.display.DisplayHandler;
import myztic.helpers.ErrorHandler;
import myztic.util.Math.radians;

import cpp.Float32;

using cpp.Native;

import myztic.display.Window;
import myztic.Scene;

// Testing-scene, soon to be used
class DummyScene extends Scene {

}
class InitScene extends Scene {
    public var window:SDLWin;
    public var myzWin:Window;

    public var glc:sdl.GLContext;

    public var shaderProgram:ShaderProgram;
    //public var vao:VAO;
    public var ebo:EBO;
    public var vbo:VBO;
    public var inputLayout:ShaderInputLayout;
    public var texture:Texture2D;

    public var world:Mat4;
    public var view:Mat4;
    public var projection:Mat4;

    override function load(win:Window) {
        super.load(win);

        myzWin = Application.focusedWindow();
        window = myzWin.backend.handle;

        final dummyScene = new DummyScene();

        final win2 = Window.create({name: "Window Test 1", init_scene: dummyScene, flags: SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE});
        final win3 = Window.create({name: "Window Test 2", init_scene: dummyScene, init_pos: [25, 25], flags: SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE});

        trace(DisplayHandler.monitors);
        trace(Application.windows);

        inline function checkCurrentWindow() {
            var cur = SDL.GL_GetCurrentWindow();
            trace("MyzWin currently is: " + Application.windows[SDL.getWindowID(cur)]);
        }
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

        setupGraphics();
    }

    override function unload(callerWindow:Window) {
        super.unload(callerWindow);
        
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
    }

    public function render():Void {
        //enable alpha shit?
        GL.glEnable(GL.GL_BLEND);
        GL.glBlendFunc(GL.GL_ONE, GL.GL_ONE_MINUS_SRC_ALPHA);

        GL.glClearColor(0, 0, 0.2, 1);
        GL.glClear(GL.GL_COLOR_BUFFER_BIT);

        shaderProgram.useProgram();

        //shaderProgram.modifyUniformVector3([1.0, (Math.sin(Timer.stamp()) / 2) + 0.5, 0.3], shaderProgram.uniforms.get("vertCol"));
        shaderProgram.uniformMatrix4fv(world, shaderProgram.getUniformLocation("world"));
        shaderProgram.uniformMatrix4fv(view, shaderProgram.getUniformLocation("camView"));
        shaderProgram.uniformMatrix4fv(projection, shaderProgram.getUniformLocation("projection"));
        //vao.bindVertexArray();
        texture.bindTexture();
        inputLayout.bindInputLayout();

        GL.glDrawElements(GL.GL_TRIANGLES, 6, GL.GL_UNSIGNED_INT, 0);

        VAO.unbindGLVertexArray();

        GL.glDisable(GL.GL_BLEND);

        SDL.GL_SwapWindow(SDL.GL_GetCurrentWindow());
    }

    inline function setupGraphics() {
        world = new Mat4();
        world = GLM.rotate(world, radians(55), new glm.Vec3(1, 0, 0));
        world = GLM.scale(world, new glm.Vec3(0.5, 0.5, 0.5));

        view = new Mat4();
        view = GLM.translate(view, new Vec3(0, 0, -10));

        projection = new Mat4();
        projection = GLM.perspective(90, myzWin.width / myzWin.height, 0.1, 100.0);

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
        vbo.changeVertexBufferData(vertices, GL.GL_STATIC_DRAW);
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

        shaderProgram.getUniformLocation("world");
        shaderProgram.getUniformLocation("camView");
        shaderProgram.getUniformLocation("projection");

        vertexShader.deleteShader();
        fragShader.deleteShader();

        myzWin.renderer.mode = Filled(true, true); // Just to have it here once
    }
}