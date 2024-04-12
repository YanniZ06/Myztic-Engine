package myztic.graphics;

import glm.Mat4;
import glm.Vec3;
import glm.GLM;

class Camera {
    public var camPos(default, set):Vec3 = new Vec3(0, 0, -5);
    //The position the camera is looking at
    public var camTarget(default, set):Vec3 = new Vec3(0, 0, 0);
    public var camFront(default, set):Vec3 = new Vec3(0, 0, -1);

    public static final UP:Vec3 = new Vec3(0, 1, 0);
    public static final ZERO:Vec3 = new Vec3(0, 0, 0);
    public static final FRONT:Vec3 = new Vec3(0, 0, -1);

    public var viewMatrix:Mat4 = new Mat4();

    //Free camera state
    public var free:Bool = false;

    private inline function viewUpdate(pos:Vec3, target:Vec3) {
        viewMatrix = GLM.lookAt(pos, target, UP);
    }

    /**
     * [Description] Makes a new Camera
     * @param position The world position the camera is stood at (Optional, default position: (0, 0, -10))
     * @param lookingAt The position the camera is looking at (Optional, default target is the zero vector)
     */
    public function new(?position:Vec3, ?lookingAt:Vec3) {
        camPos.xSet = camPos.ySet = camPos.zSet = camTarget.xSet = camTarget.ySet = camTarget.zSet = () -> {
            viewMatrix = GLM.lookAt(camPos, camTarget, UP);
        };

        if (position != null)
            camPos = position;

        if (lookingAt != null)
            camTarget = lookingAt;

        viewUpdate(camPos, camTarget);
    }
    
    public function set_camPos(n:Vec3):Vec3 {
        viewUpdate(n, camTarget);
        return camPos = n;
    }

    public function set_camTarget(n:Vec3):Vec3 {
        viewUpdate(camPos, n);
        return camTarget = n;
    }

    public function set_camFront(n:Vec3):Vec3 {
        viewUpdate(camPos, camPos.plus(n));
        return camFront = n;
    }
}