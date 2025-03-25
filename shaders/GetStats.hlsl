// see kp07.hlsl for details of this file

#include "kp07.hlsl"

// GetStats shader
// This runs on a block of 4*4 pixels and returns aggregate stats
// back to the CPU
// The CPU then does the final aggregation over all the blocks.

// input: txState (t0), txBottom (t1)
// output: two RGBA float targets, containing the aggregate information.

struct GET_STATS_OUTPUT {
    float4 target0 : SV_TARGET0;    // sum(h),  sum(Bh + 0.5*h^2),  sum(h*u),  sum(h*v)
    float4 target1 : SV_TARGET1;    // sum(h*(u^2 + v^2)),  max(u^2+v^2),  max(h),  max((|u|+c)/dx, (|v|+c)/dy)
    float target2 : SV_TARGET2;    // max((u^2+v^2)/h)
};

GET_STATS_OUTPUT GetStats( VS_OUTPUT input )
{
    const int3 idx = int3(input.tex_idx.x, input.tex_idx.y, 0) * 4;

    float sum_h = 0;
    float sum_Bhh2 = 0;
    float sum_hu = 0;
    float sum_hv = 0;
    float sum_hu2v2 = 0;
    float max_u2v2 = 0;
    float max_h = 0;
    float max_cfl = 0;
    float max_f2 = 0;
    
    for (int j = 2; j < 6; ++j) {   // add 2 to avoid ghost zones
        for (int i = 2; i < 6; ++i) {
            const int3 idx2 = idx + int3(i, j, 0);
            
            const float4 state = txState.Load(idx2);
            const float w = state.r;
            const float hu = state.g;
            const float hv = state.b;

            const float3 B_here = txBottom.Load(idx2);
            const float B = B_here.b;

            const float h = max(0, w - B);
            const float c = sqrt(g * h);
            
            float u, v;
            float divide_by_h = CalcUV_Scalar(h, hu, hv, u, v);

            sum_h += h;
            sum_Bhh2 += h*(B + 0.5f * h);
            sum_hu += hu;
            sum_hv += hv;
            sum_hu2v2 += (hu * u + hv * v);

            float u2v2 = u*u + v*v;
            max_u2v2 = max(max_u2v2, u2v2);
            max_h = max(max_h, h);
            max_cfl = max(max_cfl, (abs(u) + c) * one_over_dx);
            max_cfl = max(max_cfl, (abs(v) + c) * one_over_dy);
            max_f2 = max(max_f2, u2v2 * divide_by_h);
        }
    }

    GET_STATS_OUTPUT output;
    output.target0 = float4(sum_h, sum_Bhh2, sum_hu, sum_hv);
    output.target1 = float4(sum_hu2v2, max_u2v2, max_h, max_cfl);
    output.target2 = max_f2;

    return output;
}
