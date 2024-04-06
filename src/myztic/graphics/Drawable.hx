package myztic.graphics;

import myztic.graphics.backend.VBO;
import myztic.graphics.backend.ShaderInputLayout;
import myztic.graphics.backend.Shader.ShaderProgram;

interface Drawable {
    public function draw():Void;

    public var VBO:VBO;
    public var inputLayout:ShaderInputLayout;
    public var shaderProgram:ShaderProgram;
}