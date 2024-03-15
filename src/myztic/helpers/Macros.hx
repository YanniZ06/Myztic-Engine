package myztic.helpers;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;
import haxe.macro.Type;

import sys.io.File;
import sys.FileSystem;

class AssetMacro
{
    public static macro function copyAndMakeAssets():Void{
        final arr:Array<String> = FileSystem.readDirectory("./");
        if(arr.indexOf("output") == -1) FileSystem.createDirectory("output");
        for(fileFolder in arr) {
            //copy assets into output
            if (fileFolder == "Assets") {
                
                FileSystem.createDirectory("output/Assets");

                for (folder in FileSystem.readDirectory("Assets/")) {
                    FileSystem.createDirectory('output/Assets/$folder');

                    for (file in FileSystem.readDirectory('Assets/$folder'))
                        File.copy('Assets/$folder/$file', 'output/Assets/$folder/$file');
                }
            }
        }
    }
}

/**
 * Star Array Macro
 */
class STRMacro {
	public static var cache = new Map<String, Bool>();
	
	public static function build():ComplexType {	
		switch (Context.getLocalType()) {
			case TInst(_, [t]): // Got a class instance with a type parameter over here!
				switch (t) {
					case TInst(tRef, []):
						final type = tRef.get();
                        if(type.name == 'T') return null;
						return makeInstanceOf("StarArray",  type.pack, type.module, type.name, TypeTools.toComplexType(t) );
                    
                    case TAbstract(tRef, []):
                        final type = tRef.get();
                        if(type.name == 'T') return null;
						return makeInstanceOf("StarArray",  type.pack, type.module, type.name, TypeTools.toComplexType(t) );
                    
                    case TType(tRef, []):
						final type = tRef.get();
                        if(type.name == 'T') return null;
						return makeInstanceOf("StarArray",  type.pack, type.module, type.name, TypeTools.toComplexType(t) );

					case t: Context.error(" :: Class, Abstract or Typedefinition expected instead of: " + t, Context.currentPos());
				}
			case t: // This never happens
		}
		return null;
	}
	
	public static function makeInstanceOf(className:String, pack:Array<String>, module:String, name:String, type:ComplexType):ComplexType {		
		className += "_" + name;
		var classPackage = Context.getLocalClass().get().pack;
		
		if (cache[className] != null) return TPath({ pack:classPackage, name:className, params:[] });
        cache[className] = true;

        // We create an expression thats our <T> type path, so we can access it in sizeof as a REAL class
        var typeE:Expr = Context.parse(module + "." + name, Context.currentPos()); 

        // ---------------------------------------------- //
        var c = macro 	
        class $className {
            /**
             * The pointer to this StarArrays' data.
             */
            public var data:cpp.Star<$type>;

            /**
             * The current index of the pointer for this StarArray.
             */
            public var data_index(get, set):Int;

            /**
             * The length of this StarArray in elements.
             */
            public var length(default, null):Int;

            /**
             * The current size of this entire StarArrays' elements.
             */
            public var size(default, null):Int;
        
            private var firstIndex:cpp.Star<$type>; // THIS SHOULD NEVER CHANGE!!! but it perhaps could if you expand the memory this star uses, be cautious and wary of that!
            private var type_size:Int;
            private var __data_index:Int = 0;

            /**
             * Creates a new StarArray.
             * @param expectedElements Number of elements the StarArray is expecting without needing to be resized
             */
            public function new(expectedElements:Int = 1) {
                type_size = cpp.Native.sizeof($typeE);
                length = expectedElements;

                data = cpp.Native.malloc(type_size * expectedElements);
                untyped __cpp__('{0} = {1}', firstIndex, data); // First pointer index should be current pointer index on initialization!
                size = type_size * expectedElements;
            };
            
            /**
             * Gets the value of this StarArray at position `index`.
             * @param index The index to the element you want to aquire
             */
            public inline function get(index:Int):Null<$type> {
                data_index = index;
                return untyped __cpp__('*{0}', data);
            }
        
            /**
             * Sets the value of this StarArray at position `index` to `value`.
             * @param index The index to the element you want to set
             * @param value The value you want to assign the element 
             */
            public inline function set(index:Int, value:$type):Void {
                data_index = index;
                untyped __cpp__('*{0} = {1}', data, value);
            }

            /**
             * Gets the value at the StarArrays' current position.
             */
            public inline function getCurrent():Null<$type> {
                return untyped __cpp__('*{0}', data);
            }

            /**
             * Sets the value at the StarArrays' current position to `value`.
             * @param value Value to assign the element positioned at `index`.
             */
            public inline function setCurrent(value:$type):Void {
                untyped __cpp__('*{0} = {1}', data, value);
            }

            /**
             * Fills as many element slots from this StarArray as there are elements supplied via the second argument, starting from the given index.
             * 
             * WARNING: Keep in mind this function currently does NOT resize the array if the reserved length is exceeded.
             * 
             * Results for writing beyond the reserved length are unspecified.
             * @param index The index to start filling at. If this value is lower than one, the result is unspecified.
             * @param elements The elements to fill the array with.
             */
            public function fillFrom(index:Int, elements:Array<$type>):Void {
                untyped __cpp__('{0} = {1} + {2}', data, firstIndex, index);
                for(elem_n in 0...elements.length-1) {
                    setCurrent(elements[elem_n]);
                    incrPtr();
                }
                setCurrent(elements[elements.length-1]);
                __data_index = index;
            }

            inline function set_data_index(i:Int):Int { 
                untyped __cpp__('{0} = {1} + {2}', data, firstIndex, i); // firstIndex + i makes sure we always set our position from the beginning
                return __data_index = i;
            }
            inline function get_data_index():Int return __data_index;

            inline function incrPtr():Void untyped __cpp__('{0}++', data);
            inline function decrPtr():Void untyped __cpp__('{0}--', data);
        }
        // ---------------------------------------------- //

        Context.defineModule(classPackage.concat([className]).join('.'),[c]);
        return TPath({ pack:classPackage, name:className, params:[] });
	}
}

#end


// Old debug traces
/*var field:Array<String> = module.split(".").concat([name]);

trace('generating Class: '+classPackage.concat([className]).join('.'));	

trace("ClassName:" + className);
trace("classPackage:" + classPackage);

trace("package:" + pack);
trace("module:" + module);
trace("name:" + name);

trace("type:" + type);
trace("ElemField:" + field);*/

// trace(macro cpp.Int8);
// trace(Context.parse(module, Context.currentPos()));