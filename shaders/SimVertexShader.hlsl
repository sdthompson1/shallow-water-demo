// See kp07.hlsl for details regarding this file

#include "kp07.hlsl"

VS_OUTPUT SimVertexShader(VS_INPUT input)
{
    VS_OUTPUT output;
    output.pos.x = input.tex_idx.x * two_over_nx_plus_four - 1;
    output.pos.y = 1 - input.tex_idx.y * two_over_ny_plus_four;
    output.pos.z = 0.5f;
    output.pos.w = 1.0f;
    output.tex_idx = input.tex_idx;
    return output;
}
