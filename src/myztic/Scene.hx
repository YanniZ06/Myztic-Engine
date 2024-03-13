package myztic;

import myztic.display.Window;

class Scene {
    public function new() {}
    /**
     * Called when this Scene is loaded to a Window.
     * @param callerWindow The Window this Scene was loaded to.
     */
    public function load(callerWindow:Window):Void {}
    
    /**
     * Called each frame (for each Window this Scene is loaded to).
     * @param dt Time passed since the last frame was loaded (!!!!!!). //! REMINDER TO SET UNIT (probably seconds!!)
     */
    public function update(dt:Float):Void {}

    /**
     * Called when this Scene is unloaded from a Window.
     * @param callerWindow The Window that this Scene was unloaded from. 
     */
    public function unload(callerWindow:Window):Void {}
}