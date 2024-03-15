package myztic.display;

import sdl.SDL;

class Monitor {
    public var name:String;
    public var width:Int;
    public var height:Int;
    public var refresh_rate:Int;

    public var index:Int;
    public var modes:Array<SDLDisplayMode> = [];

    public function new(SDL_INDEX:Int) {
        index = SDL_INDEX;

        name = SDL.getDisplayName(index);
        final curMode = SDL.getCurrentDisplayMode(index);
        width = curMode.w;
        height = curMode.h;
        refresh_rate = curMode.refresh_rate;

        /*
        var desktop_mode = SDL.getDesktopDisplayMode(index);
        trace('\t Desktop Mode: ${desktop_mode.w}x${desktop_mode.h} @ ${desktop_mode.refresh_rate}Hz format:${pixel_format_to_string(desktop_mode.format)}');
        var current_mode = 
        trace('\t Current Mode: ${current_mode.w}x${current_mode.h} @ ${current_mode.refresh_rate}Hz format:${pixel_format_to_string(current_mode.format)}');*/
        
        // var modeCnt = SDL.getNumDisplayModes(index);
        /* for(display_mode in 0 ... modeCnt) {
            var mode = SDL.getDisplayMode(index, display_mode);
            trace('\t\t mode:$display_mode ${mode.w}x${mode.h} @ ${mode.refresh_rate}Hz format:${pixel_format_to_string(mode.format)}');
        }*/
    }
}