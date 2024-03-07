package myztic.display.windowUtils;

import sdl.SDL.SDLWindowFlags;

typedef WindowParams = {
    var title:String;
    var ?init_pos:Array<Int>;
    var ?init_scale:Array<Int>;
    var ?flags:SDLWindowFlags;
}