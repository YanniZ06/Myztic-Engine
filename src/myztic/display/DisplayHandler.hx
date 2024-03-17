package myztic.display;

import sdl.SDL;

import myztic.Application;
import myztic.display.Monitor;
import myztic.display.Window;

// todo: populate first on app startup!
class DisplayHandler {
    public static var monitors:Array<Monitor> = [];

    //TODO: (monitor should be changed when a SDL_WINDOWEVENT_DISPLAY_CHANGED is called in the loop)
    public static inline function getCurrentMonitor():Monitor return Application.focusedWindow().monitor;

    public static inline function refresh_AvailableMonitors():Void { // ? Rename this perhaps
        final monitorCnt = SDL.getNumVideoDisplays();

        monitors = [ for(monitor_id in 0...monitorCnt) new Monitor(monitor_id) ];
    }

    static function pixel_format_to_string(format:SDLPixelFormat) {
        return switch(format) {
            case SDL_PIXELFORMAT_UNKNOWN     :'UNKNOWN';
            case SDL_PIXELFORMAT_INDEX1LSB   :'INDEX1LSB';
            case SDL_PIXELFORMAT_INDEX1MSB   :'INDEX1MSB';
            case SDL_PIXELFORMAT_INDEX4LSB   :'INDEX4LSB';
            case SDL_PIXELFORMAT_INDEX4MSB   :'INDEX4MSB';
            case SDL_PIXELFORMAT_INDEX8      :'INDEX8';
            case SDL_PIXELFORMAT_RGB332      :'RGB332';
            case SDL_PIXELFORMAT_RGB444      :'RGB444';
            case SDL_PIXELFORMAT_RGB555      :'RGB555';
            case SDL_PIXELFORMAT_BGR555      :'BGR555';
            case SDL_PIXELFORMAT_ARGB4444    :'ARGB4444';
            case SDL_PIXELFORMAT_RGBA4444    :'RGBA4444';
            case SDL_PIXELFORMAT_ABGR4444    :'ABGR4444';
            case SDL_PIXELFORMAT_BGRA4444    :'BGRA4444';
            case SDL_PIXELFORMAT_ARGB1555    :'ARGB1555';
            case SDL_PIXELFORMAT_RGBA5551    :'RGBA5551';
            case SDL_PIXELFORMAT_ABGR1555    :'ABGR1555';
            case SDL_PIXELFORMAT_BGRA5551    :'BGRA5551';
            case SDL_PIXELFORMAT_RGB565      :'RGB565';
            case SDL_PIXELFORMAT_BGR565      :'BGR565';
            case SDL_PIXELFORMAT_RGB24       :'RGB24';
            case SDL_PIXELFORMAT_BGR24       :'BGR24';
            case SDL_PIXELFORMAT_RGB888      :'RGB888';
            case SDL_PIXELFORMAT_RGBX8888    :'RGBX8888';
            case SDL_PIXELFORMAT_BGR888      :'BGR888';
            case SDL_PIXELFORMAT_BGRX8888    :'BGRX8888';
            case SDL_PIXELFORMAT_ARGB8888    :'ARGB8888';
            case SDL_PIXELFORMAT_RGBA8888    :'RGBA8888';
            case SDL_PIXELFORMAT_ABGR8888    :'ABGR8888';
            case SDL_PIXELFORMAT_BGRA8888    :'BGRA8888';
            case SDL_PIXELFORMAT_ARGB2101010 :'ARGB2101010';
            case SDL_PIXELFORMAT_YV12        :'YV12';
            case SDL_PIXELFORMAT_IYUV        :'IYUV';
            case SDL_PIXELFORMAT_YUY2        :'YUY2';
            case SDL_PIXELFORMAT_UYVY        :'UYVY';
            case SDL_PIXELFORMAT_YVYU        :'YVYU';
            case SDL_PIXELFORMAT_NV12        :'NV12';
            case SDL_PIXELFORMAT_NV21        :'NV21';
        }
    }

}