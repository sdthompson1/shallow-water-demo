// see left_mouse.hlsl for more info about this file

#include "left_mouse.hlsl"

VS_OUTPUT LeftMouseVertexShader(VS_INPUT input)
{
    VS_OUTPUT output;

    output.tex_idx = scale * input.pos + bias;
    
    output.pos.x = output.tex_idx.x * two_over_nx_plus_four - 1;
    output.pos.y = 1 - output.tex_idx.y * two_over_ny_plus_four;
    output.pos.z = 0.5f;
    output.pos.w = 1.0f;

    output.radius = input.pos.x == 0 && input.pos.y == 0 ? 0.0f : 1.0f;

    return output;
}
