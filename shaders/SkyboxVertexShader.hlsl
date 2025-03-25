// see graphics.hlsl for more info about this file

#include "graphics.hlsl"

SKYBOX_PS_INPUT SkyboxVertexShader( float3 pos : POSITION )
{
    SKYBOX_PS_INPUT output;

    output.pos = mul(skybox_mtx, pos).xyzz;   // set w=z
    output.pos.w *= 1.0001f;  // prevent it colliding with the far clip plane

    output.tex = pos;

    return output;
}
