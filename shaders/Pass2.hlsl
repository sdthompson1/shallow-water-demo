// see kp07.hlsl for details of this file

#include "kp07.hlsl"

// Pass 2 -- Calculate fluxes

// t0: txH
// t1: txU
// t2: txV
// Output: txXFlux and txYFlux

// Runs on bulk + first ghost layer to west and south only

PASS_2_OUTPUT Pass2( VS_OUTPUT input )
{
    const int3 idx = GetTexIdx(input);
    
    const float2 h_here = txH.Load(idx).rg;                 // {hN, hE}   evaluated here
    const float hW_east = txH.Load(idx + int3(1,0,0)).a;    // hW evaluated at (j+1, k)
    const float hS_north = txH.Load(idx + int3(0,1,0)).b;   // hS evaluated at (j, k+1)

    const float2 u_here = txU.Load(idx).rg;
    const float uW_east = txU.Load(idx + int3(1,0,0)).a;
    const float uS_north = txU.Load(idx + int3(0,1,0)).b;

    const float2 v_here = txV.Load(idx).rg;
    const float vW_east = txV.Load(idx + int3(1,0,0)).a;
    const float vS_north = txV.Load(idx + int3(0,1,0)).b;
    
    // compute wave speeds
    const float2 cNE = sqrt(max(0, g * h_here.rg));    // {cN, cE} evaluated here
    const float cW = sqrt(max(0, g * hW_east));        // cW evaluated at (j+1, k)
    const float cS = sqrt(max(0, g * hS_north));       // cS evaluated at (j, k+1)

    // compute propagation speeds
    const float aplus  = max(max(u_here.g + cNE.g, uW_east + cW), 0);
    const float aminus = min(min(u_here.g - cNE.g, uW_east - cW), 0);
    const float bplus  = max(max(v_here.r + cNE.r, vS_north + cS), 0);
    const float bminus = min(min(v_here.r - cNE.r, vS_north - cS), 0);

    // compute fluxes
    PASS_2_OUTPUT output = (PASS_2_OUTPUT) 0;
    output.xflux.r = NumericalFlux(aplus,
                                   aminus,
                                   hW_east * uW_east,
                                   h_here.g * u_here.g,
                                   hW_east - h_here.g);
    
    output.xflux.g = NumericalFlux(aplus,
                                   aminus,
                                   hW_east * (uW_east * uW_east + half_g * hW_east),
                                   h_here.g * (u_here.g * u_here.g + half_g * h_here.g),
                                   hW_east * uW_east - h_here.g * u_here.g);

    output.xflux.b = NumericalFlux(aplus,
                                   aminus,
                                   hW_east * uW_east * vW_east,
                                   h_here.g * u_here.g * v_here.g,
                                   hW_east * vW_east - h_here.g * v_here.g);

    output.yflux.r = NumericalFlux(bplus,
                                   bminus,
                                   hS_north * vS_north,
                                   h_here.r * v_here.r,
                                   hS_north - h_here.r);

    output.yflux.g = NumericalFlux(bplus,
                                   bminus,
                                   hS_north * uS_north * vS_north,
                                   h_here.r * u_here.r * v_here.r,
                                   hS_north * uS_north - h_here.r * u_here.r);

    output.yflux.b = NumericalFlux(bplus,
                                   bminus,
                                   hS_north * (vS_north * vS_north + half_g * hS_north),
                                   h_here.r * (v_here.r * v_here.r + half_g * h_here.r),
                                   hS_north * vS_north - h_here.r * v_here.r);

    return output;
}
