package myztic.util;

import glm.Mat4;

class Math {
    public static inline function radians(degrees:Float):Float {
        return degrees * std.Math.PI / 180;
    }

    private static var arr:Array<Array<cpp.Float32>> = [
        [1, 0, 0, 0], 
        [0, 1, 0, 0], 
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ];

    public static inline function makeMatrixIdentity(mat:Mat4) {
        for (column in 0...arr.length) 
            for (row in 0...arr[column].length)
                mat.set(column, row, arr[column][row]);
    }
}