// see kp07.hlsl for details of this file

#include "kp07.hlsl"

float4 EastBoundary( VS_OUTPUT input ) : SV_TARGET
{
    int3 idx = int3(reflect_x - int(input.tex_idx.x), int(input.tex_idx.y), 0);
    float4 real = txState.Load(idx);
    float B = txBottom.Load(idx).b;

    float w_real = real.r;
    float hu_real = real.g;
    float hv_real = real.b;
    float h_real = w_real - B;

    float w_ghost;
    float hu_ghost;
    float hv_ghost;

    float SL = CalcSeaLevel(input.tex_idx);
    
    if (B > SL && solid_wall_flag) {
        w_ghost = w_real;
        hu_ghost = -hu_real;
        hv_ghost = hv_real;
    } else {
        FixedHBoundary(max(0, SL - B), h_real, hu_real, w_ghost, hu_ghost);
        w_ghost += B;
        hv_ghost = 0;
    }

    return float4(w_ghost, hu_ghost, hv_ghost, 0);
}
