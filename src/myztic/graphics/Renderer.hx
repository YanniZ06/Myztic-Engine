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
                var face:Int = -1;
                var mode:Int = -1;
                getPolyModeFromEnum(mode, cpp.Native.addressOf(face), cpp.Native.addressOf(mode));

                OpenGL.glPolygonMode(face, mode);
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
    }

    inline function getGLface(f:Bool, b:Bool):Int {
        return switch([f, b]) {
            case [true, false]: OpenGL.GL_FRONT;
            case [false, true]: OpenGL.GL_BACK;
            case [true, true]: OpenGL.GL_FRONT_AND_BACK;
        }
    }

    // I dont wanna return an array for this so im using pointers, c++ style
    inline function getPolyModeFromEnum(mode:RenderMode, inFace:cpp.Star<cpp.UInt32>, inMode:cpp.Star<cpp.UInt32>) {
        switch(mode) {
            case VertexCoords(front, back):
                untyped __cpp__('
                    *{0} = {1};
                    *{2} = {3}', inFace, getGLface(front, back), inMode, OpenGL.GL_POINT);
            case PolygonOutlines(front, back):
                untyped __cpp__('
                    *{0} = {1};
                    *{2} = {3}', inFace, getGLface(front, back), inMode, OpenGL.GL_LINE);
            case Filled(front, back):
                untyped __cpp__('
                    *{0} = {1};
                    *{2} = {3}', inFace, getGLface(front, back), inMode, OpenGL.GL_FILL);
        }
    }
}