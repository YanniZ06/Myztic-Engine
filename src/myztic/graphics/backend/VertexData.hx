package myztic.graphics.backend;

import cpp.Native;
import cpp.Float32;

abstract VertexData(Array<Float32>) from Array<Float32> to Array<Float32> {
    public function new(positions:Array<Float32>, ?colors:Array<Float32>, ?textureCoords:Array<Float32>, ?normals:Array<Float32>) {
        this = [];
        
    }

    @:to
    public function toArray():Array<Float32> {
        return this;
    }
}