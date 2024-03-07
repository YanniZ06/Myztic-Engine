package sdl_extend;

import cpp.VirtualArray.NativeVirtualArray;
import sdl.SDL;
import sdl.Window;

@:unreflective @:keep @:include('SDL_messagebox.h')
@:structAccess @:native('SDL_MessageBoxData')
extern class SDL_MessageBoxData {
    var flags:cpp.UInt32;
    var window:Window;

    var title:cpp.ConstCharStar;
    var message:cpp.ConstCharStar;
    
    var numbuttons:Int;
    var buttons:cpp.ConstStar<SDL_MessageBoxButtonData>;
    var colorScheme:cpp.ConstStar<SDL_MessageBoxColorScheme>;
}

@:unreflective @:keep @:include('SDL_messagebox.h')
@:structAccess @:native('SDL_MessageBoxColor')
extern class SDL_MessageBoxColor {
    var r:cpp.UInt8;
    var g:cpp.UInt8;
    var b:cpp.UInt8;
}

@:unreflective @:keep @:include('SDL_messagebox.h')
@:structAccess @:native('SDL_MessageBoxColorScheme')
extern class SDL_MessageBoxColorScheme {
    var colors:cpp.RawPointer<SDL_MessageBoxColor>; // This is a c++ array. Yeah. Thats right
}

@:unreflective @:keep @:include('SDL_messagebox.h')
@:structAccess @:native('SDL_MessageBoxButtonData')
extern private class SDL_MessageBoxButtonData {
    var flags:cpp.UInt32;
    var buttonid:Int;
    var text:cpp.ConstCharStar;
}

typedef MsgBoxButton = {
    var rawData:SDL_MessageBoxButtonData;
    var callerFunc:Void->Void; 
};

/*class ArrayCPP<T> {
    var handler:cpp.Star<T>;
    public function new<T>(member:T) {
        handler = untyped __cpp__('&member');
    }
}*/

class MessageBoxSys {
    static var msgBoxButtonCount:Int = 0;

    public static function makeMsgBoxButton(name:cpp.ConstCharStar, onPress:Void->Void):MsgBoxButton {
        var rawdata:SDL_MessageBoxButtonData = untyped __cpp__('{0, ::sdl_extend::MessageBoxSys_obj::msgBoxButtonCount++, name}');
        return {
            rawData: rawdata,
            callerFunc: onPress
        };
    }

    public static function showCustomMessageBox(title:cpp.ConstCharStar, message:cpp.ConstCharStar, window:Window, flags:SDLMessageBoxFlags, buttons:Array<MsgBoxButton>):Int {
        var boxData:SDL_MessageBoxData = untyped __cpp__('{0, NULL, "", "", 0, NULL, NULL}');
        boxData.title = title;
        boxData.message = message;
        boxData.window = window;
        boxData.flags = flags;

        final len:Int = buttons.length;

        /* var rawArr:Array<SDL_MessageBoxButtonData> = [];
        for(b in buttons) rawArr.push(b.rawData); */
        var btnArrayPtr:cpp.Star<SDL_MessageBoxButtonData> = cpp.Native.malloc(cpp.Native.sizeof(SDL_MessageBoxButtonData) * len);
        // btnArrayPtr = untyped __cpp__('(SDL_MessageBoxButtonData *) {0}->Pointer()', rawArr); // Seems pointless with custom data. Whyever it does that!!
        for(i in 0...len) {
            var data:SDL_MessageBoxButtonData = buttons[len - (i+1)].rawData;
            untyped __cpp__('
                *btnArrayPtr = data;
                btnArrayPtr++;
            ');
        }
        untyped __cpp__('btnArrayPtr -= {0}', len);

        var const_btnArrayPtr:cpp.ConstStar<SDL_MessageBoxButtonData> = untyped __cpp__ ('const_cast<const SDL_MessageBoxButtonData*>({0})', btnArrayPtr);

        boxData.buttons = const_btnArrayPtr;
        boxData.numbuttons = buttons.length;
        boxData.colorScheme = untyped __cpp__('NULL');

        var btnPressed:Int = 0;
        var boxResult:Int = 0;
        untyped __cpp__('
            const SDL_MessageBoxData* data = &{0};

            boxResult = SDL_ShowMessageBox(
                data,
                &btnPressed
            );
        ', boxData);

        buttons[btnPressed].callerFunc();
        msgBoxButtonCount = 0;
        return boxResult;
    }
}