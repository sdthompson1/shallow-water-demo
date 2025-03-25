// see kp07.hlsl for details of this file

#include "kp07.hlsl"

// Pass 3 -- Do timestep and calculate new w_bar, hu_bar, hv_bar.

// t0: txState
// t1: txBottom
// t2: txXFlux
// t3: txYFlux
// Output: New txState

// Runs on interior points only

float FrictionCalc(float h, float u)
{
    return max(h*u*dt*0.2f, friction * h * abs(u) * u);
}

float4 Pass3( VS_OUTPUT input ) : SV_Target
{
    const int3 idx = GetTexIdx(input);
    const float3 B_here = txBottom.Load(idx);

    float4 result;
    
    const float3 in_state = txState.Load(idx).rgb;   // w, hu and hv (cell avgs, evaluated here)
        
    const float3 xflux_here = txXFlux.Load(idx).rgb;
    const float3 xflux_west = txXFlux.Load(idx + int3(-1,0,0)).rgb;
    const float3 yflux_here = txYFlux.Load(idx).rgb;
    const float3 yflux_south = txYFlux.Load(idx + int3(0,-1,0)).rgb;
        
    const float BX_west = txBottom.Load(idx + int3(-1,0,0)).g;
    const float BY_south = txBottom.Load(idx + int3(0,-1,0)).r;

    // friction calculation
    const float h = max(0, in_state.r - B_here.b);
    float u, v;
    CalcUV_Scalar(h, in_state.g, in_state.b, u, v);

    const float3 source_term = 
        float3(0,
               -g_over_dx * h * (B_here.g - BX_west)   - FrictionCalc(h, u),
               -g_over_dy * h * (B_here.r - BY_south)  - FrictionCalc(h, v));
        
    const float3 d_by_dt =
        (xflux_west - xflux_here) * one_over_dx
        + (yflux_south - yflux_here) * one_over_dy
        + source_term;
        
    // simple Euler time stepping
    const float3 result3 = in_state + d_by_dt * dt;
    result = float4(result3.r, result3.g, result3.b, 0);

    return result;
}
