package sdl_extend;

import sdl_extend.Mouse.MouseHelper.sdl_button;
enum abstract MouseButton(Int) from Int to Int {
    var SDL_BUTTON_LEFT:MouseButton =     1;
    var SDL_BUTTON_MIDDLE:MouseButton =   2;
    var SDL_BUTTON_RIGHT:MouseButton =    3;
    var SDL_BUTTON_X1:MouseButton =       4;
    var SDL_BUTTON_X2:MouseButton =       5;
    var SDL_BUTTON_LMASK:MouseButton =    sdl_button(SDL_BUTTON_LEFT);
    var SDL_BUTTON_MMASK:MouseButton =    sdl_button(SDL_BUTTON_MIDDLE);
    var SDL_BUTTON_RMASK:MouseButton =    sdl_button(SDL_BUTTON_RIGHT);
    var SDL_BUTTON_X1MASK:MouseButton =   sdl_button(SDL_BUTTON_X1);
    var SDL_BUTTON_X2MASK:MouseButton =   sdl_button(SDL_BUTTON_X2);
}

class MouseHelper {
    public static inline function sdl_button(x:Int):Int return (1 << ((x)-1));
}