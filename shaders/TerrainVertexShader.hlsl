// see graphics.hlsl for info about this file

#include "graphics.hlsl"


// Vertex Shader for Terrain

TERRAIN_PS_INPUT TerrainVertexShader( VS_INPUT input )
{
    TERRAIN_PS_INPUT output;

    // lookup texture values at the input point
    const int3 tpos = int3(input.pos.x, input.pos.y, 0);
    const float3 tex_value = txHeightfield.Load( tpos );

    // compute position in clip space
    const float4 pos_in = float4( input.pos.x, input.pos.y, tex_value.r, 1 );
    output.pos = mul( tex_to_clip, pos_in );

    const float3 norm = float3(-tex_value.g, -tex_value.b, 1.0f);
    output.normal = normalize(norm);

    // texture coords.
    // TODO: the tex coords might be better input in the vertex buffer rather than calculated here.
    output.tex_coord = terrain_tex_scale * float2(input.pos.x - 2, input.pos.y - 2);
    
    return output;
}

