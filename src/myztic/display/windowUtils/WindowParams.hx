package myztic.display.windowUtils;

import myztic.Scene;
import sdl.SDL.SDLWindowFlags;

typedef WindowParams = {
    var name:String;
    var init_scene:Scene;
    var ?init_pos:Array<Int>;
    var ?init_scale:Array<Int>;
    var ?flags:SDLWindowFlags;
    var ?fps:Int;
}