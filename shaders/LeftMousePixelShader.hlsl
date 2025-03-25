// see left_mouse.hlsl for more info about this file

#include "left_mouse.hlsl"

float4 LeftMousePixelShader(VS_OUTPUT input) : SV_TARGET
{
    const int3 idx = int3(input.tex_idx.x, input.tex_idx.y, 0);
    float4 current = txState.Load(idx);
    float B = txBottom.Load(idx).b;

    float dh = disp_A + disp_B * input.radius;
    
    
    float old_w = current.r;
    float old_h = old_w - B;
    float new_w = max(B, old_w + dh);
    float new_h = new_w - B;

    // crude velocity calculation. no need to do the full "epsilon" treatment, we will just put a min on
    // old_h, which has the effect of lowering the velocity if h is currently small.
    float limited_old_h = max(0.5f, old_h);
    float old_u = current.g / limited_old_h;
    float old_v = current.b / limited_old_h;
    float new_hu = new_h * old_u;
    float new_hv = new_h * old_v;
    
    return float4(new_w, new_hu, new_hv, 0);
}
