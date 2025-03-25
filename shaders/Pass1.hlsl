// see kp07.hlsl for details of this file

#include "kp07.hlsl"


// Pass 1 -- Reconstruct h, u, v at the four edges of each cell.

// t0: txState
// t1: txBottom
// Output: txH, txU, txV, txNormal

// Runs on bulk + first ghost layer either side

PASS_1_OUTPUT Pass1(VS_OUTPUT input)
{
    // Read in relevant texture values

    const int3 idx = int3(input.tex_idx.x, input.tex_idx.y, 0);

    // in = {w, hu, hv, _} (cell average)
    const float4 in_here = txState.Load(idx);
    const float4 in_south = txState.Load(idx + int3(0, -1, 0));
    const float4 in_north = txState.Load(idx + int3(0, 1, 0));
    const float4 in_west = txState.Load(idx + int3(-1, 0, 0));
    const float4 in_east = txState.Load(idx + int3(1, 0, 0));

    float4 B;     // {BN, BE, BS, BW}
    B.rg = txBottom.Load(idx).rg;
    B.b = txBottom.Load(idx + int3(0, -1, 0)).r;
    B.a = txBottom.Load(idx + int3(-1, 0, 0)).g;
    
    
    // Reconstruct w, hu and hv at the four cell edges (N, E, S, W)
    
    float4 w;    // {wN, wE, wS, wW}
    float4 hu;   // {huN, huE, huS, huW}
    float4 hv;   // {hvN, hvE, hvS, hvW}
    
    Reconstruct(in_west.r, in_here.r, in_east.r, w.a, w.g);
    Reconstruct(in_south.r, in_here.r, in_north.r, w.b, w.r);
    
    Reconstruct(in_west.g, in_here.g, in_east.g, hu.a, hu.g);
    Reconstruct(in_south.g, in_here.g, in_north.g, hu.b, hu.r);
    
    Reconstruct(in_west.b, in_here.b, in_east.b, hv.a, hv.g);
    Reconstruct(in_south.b, in_here.b, in_north.b, hv.b, hv.r);


    // Correct the w values to ensure positivity of h

    CorrectW(B.a, B.g, in_here.r, w.a, w.g);    // wW and wE (from BW, BE, wbar)
    CorrectW(B.b, B.r, in_here.r, w.b, w.r);    // wS and wN (from BS, BN, wbar)


    // Reconstruct h from (corrected) w
    // Calculate u and v from h, hu and hv

    PASS_1_OUTPUT output;
    output.h = w - B;
    CalcUV(output.h, hu, hv, output.u, output.v);


    // Calculate normal 

    float3 normal;
    //normal.x = (w.g - w.a) * one_over_dx;
    //normal.y = (w.r - w.b) * one_over_dy;
    //normal.z = -1;
    normal.x = (in_west.r - in_east.r) * one_over_dx;
    normal.y = (in_south.r - in_north.r) * one_over_dy;
    normal.z = 2;
    normal = normalize(normal);
    output.n = float4(normal.x, normal.y, normal.z, 0);
    
    return output;
}
