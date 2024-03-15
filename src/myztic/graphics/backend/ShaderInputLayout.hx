package myztic.graphics.backend;

import opengl.OpenGL as GL;
import opengl.OpenGL.GLfloat;
import myztic.helpers.ErrorHandler.checkGLError;

enum InputPropertyType
{
    Position;
    Color;
    TextureCoordinate;
    Normal;
}

typedef InputProperty = {
    var type:InputPropertyType;
    var size:Int;
    var glType:Int;
    var pointerOffset:Int;
};

typedef LayoutDescription = {
    var inputProperties:Array<InputProperty>;
    var elementCount:Int;
};

class ShaderInputLayout
{
    public static final POSITION:InputProperty = {type: Position, size: 3, glType: GL.GL_FLOAT, pointerOffset: -9};
    public static final COLOR:InputProperty = {type: Color, size: 3, glType: GL.GL_FLOAT, pointerOffset: -9};
    public static final TEXCOORD:InputProperty = {type: TextureCoordinate, size: 2, glType: GL.GL_FLOAT, pointerOffset: -9};
    public static final NORMAL:InputProperty = {type: Normal, size: 3, glType: GL.GL_FLOAT, pointerOffset: -9};

    /**
     * [Description] Create input layout description which is passed into createInputLayout
     * @param inputProperties Array of typedef InputProperty which consists of `type:InputPropertyType` `size:Int` `glType:Int` `pointerOffset:Int`, pointerOffset is automatically calculated
     * @return LayoutDescription
     */
    public static function createLayoutDescription(inputProperties:Array<InputProperty>):LayoutDescription {
        var elementCount:Int = 0;

        for (inputProperty in inputProperties) {
            inputProperty.pointerOffset = elementCount;
            elementCount += inputProperty.size;
        }

        return {elementCount: elementCount, inputProperties: inputProperties};
    }

    public var propertyCount:Int = 0;
    public var description:LayoutDescription;
    public var attachedVAO:VAO;

    private function new() 
        attachedVAO = VAO.make();

    public inline function bindInputLayout():Void 
        attachedVAO.bindVertexArray();

    public static inline function unbindAllInputLayouts():Void {
        VAO.unbindGLVertexArray();
        checkGLError();
    }

    public function deleteInputLayout():Void {
        attachedVAO.deleteArrayObject();
        checkGLError();
        description = null;
        propertyCount = 0;
    }

    /**
     * [Description] Enables a specific attribute
     * @param index Enables that attribute by index (You should know which index it is from the InputProperties you passed in)
     */
    public function enableAttrib(index:Int):Void {
        if (index > propertyCount)
            throw 'Could not enable attrib index greater than the max attrib count';

        GL.glEnableVertexAttribArray(index);
        checkGLError();
    }

    /**
     * [Description] Enables all of our input layout attributes 
     * @return Void 
     */
    public inline function enableAllAttribs():Void {
        for (i in 0...propertyCount) {
            GL.glEnableVertexAttribArray(i);
            checkGLError();
        }
    }

    /**
     * [Description] Disables all of our input layout attributes
     * @return Void 
     */
    public inline function disableAllAttribs():Void {
        for (i in 0...propertyCount){
            GL.glDisableVertexAttribArray(i);
            checkGLError();
        }
    }

    /**
     * [Description] Creates a Shader Input Layout that specifies the current active shader input
     * @param descriptions LayoutDescriptions which defines what properties are going in and what they do
     * @return ShaderInputLayout
     */
    public static function createInputLayout(description:LayoutDescription):ShaderInputLayout {
        final previousInputLayoutVAO:Int = -9;
        GL.glGetIntegerv(GL.GL_VERTEX_ARRAY_BINDING, cpp.Native.addressOf(previousInputLayoutVAO));
        checkGLError();

        final ret:ShaderInputLayout = new ShaderInputLayout();
        ret.bindInputLayout();

        for (inputProperty in description.inputProperties) {
            //make the vertex info :grimp:
            GL.glVertexAttribPointer(ret.propertyCount, inputProperty.size, inputProperty.glType,
            false, description.elementCount * cpp.Native.sizeof(GLfloat), inputProperty.pointerOffset * cpp.Native.sizeof(GLfloat));
            ret.propertyCount++;
            checkGLError();
        }
        
        ret.description = description;

        if (previousInputLayoutVAO != 0) {
            GL.glBindVertexArray(previousInputLayoutVAO);
            checkGLError();
        }

        return ret;
    }
}