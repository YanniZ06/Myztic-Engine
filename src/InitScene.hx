package;

import myztic.display.Window;
import myztic.Scene;

// Testing-scene, soon to be used
class InitScene extends Scene {
    override function load(win:Window) {
        super.load(win);

        myzWin = Application.focusedWindow();
        window = myzWin.backend.handle;

        final win2 = MyzWin.create({name: "Window Test 1", init_scene: iSc, flags: SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE});
        final win3 = MyzWin.create({name: "Window Test 2", init_scene: iSc, init_pos: [25, 25], flags: SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE});

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

    inline function setupGraphics() {
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

        //shaderProgram.getUniformLocation("vertCol");

        vertexShader.deleteShader();
        fragShader.deleteShader();

        // GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_FILL); // window.renderer.mode = NORMAL; (????)
    }
}