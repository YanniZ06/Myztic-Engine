package myztic.graphics;

import glm.Mat4;
import glm.Vec3;
import glm.GLM;

class Camera {
    public var camPos(default, set):Vec3 = new Vec3(0, 0, 3);
    //Camera look vector (Changed by mouse in freecam mode)
    public var camLook(default, set):Vec3 = new Vec3(0, 0, -1);

    public static var UP(default, never):Vec3 = new Vec3(0, 1, 0);
    public static var ZERO(default, never):Vec3 = new Vec3(0, 0, 0);
    public static var FRONT(default, never):Vec3 = new Vec3(0, 0, -1);

    public var viewMatrix:Mat4 = new Mat4();

    //Free camera state
    public var free:Bool = false;

    private inline function viewUpdate(pos:Vec3) {
        viewMatrix = GLM.lookAt(pos, camLook.plus(camPos) , UP);
    }

    /**
     * [Description] Makes a new Camera
     * @param position The world position the camera is stood at (Optional, default position: (0, 0, -10))
     * @param lookingAt The position the camera is looking at (Optional, default target is the zero vector)
     */
    public function new(?position:Vec3, ?lookingAt:Vec3) {
        camPos.xSet = camPos.ySet = camPos.zSet = camLook.xSet = camLook.ySet = camLook.zSet = () -> {
            viewUpdate(camPos);
        };

        if (position != null)
            camPos = position;

        if (lookingAt != null)
            camLook = lookingAt;

        viewUpdate(camPos);
    }
    
    public function set_camPos(n:Vec3):Vec3 {
        viewUpdate(n);
        return camPos = n;
    }

    public function set_camLook(n:Vec3):Vec3 {
        viewUpdate(camPos);
        return camLook = n;
    }
}