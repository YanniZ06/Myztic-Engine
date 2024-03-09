package myztic.util;

#if macro

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;
import haxe.macro.Type;

/**
 * Star Array Macro
 */
class STRMacro {
	public static var cache = new Map<String, Bool>();
	
	public static function build():ComplexType {	
		switch (Context.getLocalType()) {
			case TInst(_, [t]): // Got a class instance with a type parameter over here!
				switch (t) {
					case TInst(n, []):
						final g = n.get();						
						return buildClass("StarArray_I",  g.pack, g.module, g.name, TypeTools.toComplexType(t) );
                    
                    case TAbstract(n, []):
                        final g = n.get();
                        return buildClass("StarArray_I",  g.pack, g.module, g.name, TypeTools.toComplexType(t) );

					case t: Context.error(" :: Class or abstract expected instead of " + t, Context.currentPos());
				}
			case t: Context.error(" :: Class 'StarArray_I' expected instead of " + t, Context.currentPos());
		}
		return null;
	}
	
	public static function buildClass(className:String, pack:Array<String>, module:String, name:String, type:ComplexType):ComplexType {		
		className += "_" + name;
		var classPackage = Context.getLocalClass().get().pack;
		
		if (cache[className] != null) return TPath({ pack:classPackage, name:className, params:[] });
        cache[className] = true;
        
        var field:Array<String> = module.split(".").concat([name]);
        
        trace('generating Class: '+classPackage.concat([className]).join('.'));	
        
        trace("ClassName:" + className);
        trace("classPackage:" + classPackage);
        
        trace("package:" + pack);
        trace("module:" + module);
        trace("name:" + name);
        
        trace("type:" + type);
        trace("ElemField:" + field);
        
        // ---------------------------------------------- //
        var c = macro 	
        class $className {
            public var value:$type;

            public function new(value:$type) {
                this.value = value;
            }
            
            public function process() {
                trace( $v{name} );
            }
        }
        // ---------------------------------------------- //

        Context.defineModule(classPackage.concat([className]).join('.'),[c]);
        return TPath({ pack:classPackage, name:className, params:[] });
	}
}

#end