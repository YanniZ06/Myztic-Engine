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
import myztic.graphics.backend.EBO;
import myztic.graphics.backend.Shader;
import myztic.graphics.backend.ShaderInputLayout;
import myztic.graphics.backend.Texture2D;
import myztic.helpers.StarArray;
import myztic.Application;
import myztic.display.Window;
import myztic.Scene;
import myztic.helpers.ErrorHandler.checkGLError;
import myztic.display.DisplayHandler;
import myztic.helpers.ErrorHandler;
import myztic.util.Math.radians;
import myztic.graphics.Camera;

import cpp.Float32;

using cpp.Native;

// Testing-scene, soon to be used
class DummyScene extends Scene {

}
@:headerInclude('gtc/matrix_transform.hpp')
class InitScene extends Scene {
    public var window:SDLWin;
    public var myzWin:Window;

    public var glc:sdl.GLContext;

    public var shaderProgram:ShaderProgram;
    public var ebo:EBO;
    public var vbo:VBO;
    public var inputLayout:ShaderInputLayout;
    public var texture:Texture2D;

    public var world:Mat4;
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
        
        var compiled = SDL.VERSION();
        var linked = SDL.getVersion();
        trace("Versions:");
        trace('    - We compiled against SDL version ${compiled.major}.${compiled.minor}.${compiled.patch} ...');
        trace('    - And linked against SDL version ${linked.major}.${linked.minor}.${linked.patch}');

        final maxVtxAttribs:cpp.Int32 = 0;
        GL.glGetIntegerv(GL.GL_MAX_VERTEX_ATTRIBS, maxVtxAttribs.addressOf());
        trace("Max available vertex attribs (vertex shader input): " + maxVtxAttribs);
        myztic.helpers.ErrorHandler.checkGLError();

        //setting up camera, model position and the projection
        world = new Mat4();
        //world = GLM.rotate(world, radians(25), new glm.Vec3(1, 0, 0));
        world = GLM.scale(world, new glm.Vec3(0.5, 0.5, 0.5));

        final f:Float32 = Std.parseFloat('${myzWin.width}');
        final e:Float32 = Std.parseFloat('${myzWin.height}');

        //projection should be remade everytime window resolution changes
        projection = GLM.perspective(45, myzWin.width / myzWin.height, 0.1, 100.0);

        setupGraphics();
    }

    override function unload(callerWindow:Window) {
        super.unload(callerWindow);
        
        vbo.unbind();
        GL.glBindVertexArray(0);
        ebo.unbind();
        texture.unbind();
        GL.glUseProgram(0);
        inputLayout.disableAllAttribs();

        vbo.delete();
        ebo.delete();
        texture.delete();
        inputLayout.deleteInputLayout();
        shaderProgram.delete();        
    }

    public function render():Void {
        //enable alpha shit?
        GL.glEnable(GL.GL_BLEND);
        GL.glBlendFunc(GL.GL_ONE, GL.GL_ONE_MINUS_SRC_ALPHA);

        GL.glClearColor(0, 0, 0.2, 1);
        GL.glClear(GL.GL_COLOR_BUFFER_BIT);

        shaderProgram.bind();

        //shaderProgram.modifyUniformVector3([1.0, (Math.sin(Timer.stamp()) / 2) + 0.5, 0.3], shaderProgram.uniforms.get("vertCol"));
        shaderProgram.uniformMatrix4fv(world, shaderProgram.getUniformLocation("world"));
        shaderProgram.uniformMatrix4fv(Main.camera.viewMatrix, shaderProgram.getUniformLocation("camView"));
        shaderProgram.uniformMatrix4fv(projection, shaderProgram.getUniformLocation("projection"));
        texture.bind();
        inputLayout.bindInputLayout();

        //Main.camera.camPos.z -= 0.01;

        GL.glDrawElements(GL.GL_TRIANGLES, 6, GL.GL_UNSIGNED_INT, 0);

        GL.glBindVertexArray(0);

        GL.glDisable(GL.GL_BLEND);

        SDL.GL_SwapWindow(SDL.GL_GetCurrentWindow());
    }

    inline function setupGraphics() {
        var vertices:StarArray<GLfloat> = new StarArray<GLfloat>(24);
        vertices.fillFrom(0, 
            [
                //vtx is position, color, texcoord
                0.5, 0.5, 0.0, 
                1.0, 0.0,

                0.5, -0.5, 0.0,
                1.0, 1.0, 

                -0.5, -0.5, 0.0,
                0.0, 1.0,

                -0.5, 0.5, 0.0,
                0.0, 0.0
            ]
        );
        
        vertices.data_index = 0;
        
        var indices:StarArray<cpp.UInt32> = new StarArray<cpp.UInt32>(6);
        indices.fillFrom(0, [0, 1, 3, 1, 2, 3]);
        indices.data_index = 0;

        ebo = EBO.make();
        vbo = VBO.make();

        vbo.bind();
        vbo.fill(vertices, GL.GL_STATIC_DRAW);
        texture = Texture2D.fromFile("Glint.png");

        inputLayout = ShaderInputLayout.createInputLayout(ShaderInputLayout.createLayoutDescription([ShaderInputLayout.POSITION, ShaderInputLayout.TEXCOORD]));
        inputLayout.enableAllAttribs();

        ebo.bind();
        ebo.fill(indices);

        vbo.unbind();

        var vertexShader:Shader = new Shader(GL.GL_VERTEX_SHADER, "VS.glsl");
        var fragShader:Shader = new Shader(GL.GL_FRAGMENT_SHADER, "FS.glsl");

        shaderProgram = new ShaderProgram();
        shaderProgram.fill(vertexShader);
        shaderProgram.fill(fragShader);

        shaderProgram.link();

        shaderProgram.bind();

        shaderProgram.getUniformLocation("world");
        shaderProgram.getUniformLocation("camView");
        shaderProgram.getUniformLocation("projection");

        vertexShader.deleteShader();
        fragShader.deleteShader();

        myzWin.renderer.mode = Filled(true, true); // Just to have it here once
    }
}