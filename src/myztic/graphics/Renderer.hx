package myztic.graphics;

import opengl.OpenGL;
import myztic.display.Window;
import myztic.graphics.shapes.Triangle;

enum RenderTask {
    RenderTri(tri:Triangle);
    RenderTriCollection(clc:TriangleCollection);

    // Special Tasks
    SwitchRenderMode(mode:RenderMode);
}

/**
 * The RenderMode describes how polygons are drawn by the renderer.
 * 
 * Every RenderMode has a `front` and `back` value, dictating whether front-facing and/or back-facing polygons should be rendered.
 */
enum RenderMode {
    /**
     * Only points representing the handed in vertex coordinates are rendered.
     */
    VertexCoords(front:Bool, back:Bool);
    /**
     * The outlines of the polygons made up by the vertex coordinates are rendered.
     */
    PolygonOutlines(front:Bool, back:Bool);
    /**
     * The polygons are fully rendered and filled in.
     * 
     * This is the default mode.
     */
    Filled(front:Bool, back:Bool);
}

class Renderer {
    public function new(win:Window) { window = win; }
    
    /**
     * The window this renderer is tied to.
     */
    public var window:Window;

    /**
     * The queued tasks of this renderer to be executed on the next draw call of the window.
     */
    public var tasks:Array<RenderTask> = [];

    // todo: Figure out types, maybe make another enum
    // todo: rename, also give purpose
    // todo: this should contain everything the renderer needs to "bind" or "enable" to render what has been tasked to render and prepared by "execute"!!
    public var toBind:Array<Dynamic> = []; 

    /**
     * The way the renderer should display the handed render-information.
     */
    public var mode(default, set):RenderMode = Filled(true, true);

    /**
     * When called, the renderer executes all of its queued tasks.
     * To display the rendered graphics, call "displayRender".
     */
    public function execute() {
        for(task in tasks) switch(task) {
            case RenderTri(tri): // todo: Perhaps split up tasks more?

            case RenderTriCollection(clc):

            case SwitchRenderMode(mode):
                final polymodeVals = getPolyModeFromEnum(mode);

                OpenGL.glPolygonMode(polymodeVals[0], polymodeVals[1]);
        }
    }

    /**
     * Displays everything that has been rendered in the last `execute` call.
     * 
     * If you are calling this function manually outside of the draw-loop, it is recommended to ensure the correct context is enabled.
     */
    public function displayRender() {
        // todo: enable / bind necessary components and call gl draw functions. should window swapping also be done here???
    }

    // Render Mode
    inline function set_mode(m:RenderMode) {
        tasks.push(SwitchRenderMode(m));
        return mode = m;
    }

    inline function getGLface(f:Bool, b:Bool):Int {
        return switch([f, b]) {
            case [true, false]: OpenGL.GL_FRONT;
            case [false, true]: OpenGL.GL_BACK;
            case [true, true]: OpenGL.GL_FRONT_AND_BACK;
            case _: OpenGL.GL_FRONT_AND_BACK;
        }
    }

    inline function getPolyModeFromEnum(mode:RenderMode):Array<Int> {
        return switch(mode) {
            case VertexCoords(front, back): [getGLface(front, back), OpenGL.GL_POINT];
            case PolygonOutlines(front, back): [getGLface(front, back), OpenGL.GL_LINE];
            case Filled(front, back): [getGLface(front, back), OpenGL.GL_FILL];
        }
    }
}