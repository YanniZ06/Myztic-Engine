package myztic.graphics;

import myztic.display.Window;
import myztic.graphics.shapes.Triangle;

enum RenderTask {
    RenderTri(tri:Triangle);
    RenderTriCollection(clc:TriangleCollection);

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
     * When called, the renderer executes all of its queued tasks.
     * To display the rendered graphics, call "displayRender".
     */
    public function execute() {
        for(task in tasks) switch(task) {
            case RenderTri(tri): // todo: Perhaps split up tasks more?

            case RenderTriCollection(clc):

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
}