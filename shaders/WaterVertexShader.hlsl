// see graphics.hlsl for more info about this file

#include "graphics.hlsl"


// Vertex Shader for Water

WATER_PS_INPUT WaterVertexShader( VS_INPUT input )
{
    WATER_PS_INPUT output;

    // lookup the terrain level
    const int3 idx = int3(input.pos.x, input.pos.y, 0);
    const float3 ground_tex = txHeightfield.Load(idx);
    const float B = ground_tex.r;
    const float3 ground_normal = normalize(float3(-ground_tex.g, -ground_tex.b, 1));
    
    // lookup the water level
    float w = txWater.Load(idx).r;

    // simple way to ensure there is no "gap" at the edge of the box
    if (idx.x==2 || idx.y==2 || idx.x==nx_plus_1 || idx.y==ny_plus_1) w=B;

    // calculate water depth, this is used in the pixel shader
    output.water_depth = w - B;

    // compute position in clip space
    const float dmin = 0.05f;
    const float vert_bias = (output.water_depth < dmin ? 2*(output.water_depth - dmin) : 0);
    const float4 pos_in = float4( input.pos.x, input.pos.y, w + vert_bias, 1 );
    output.pos = mul( tex_to_clip, pos_in );

    // now compute the normal
    output.normal = txNormal.Load(idx).rgb;

    // now compute the eye vector (from vertex towards camera)
    output.eye = normalize(eye_mult * pos_in.xyz + eye_trans);
    
    // send the world pos (xy) through, for refraction calculations
    output.world_pos = world_mult * pos_in.xy + world_trans;

    output.terrain_normal = ground_normal;
    
    return output;
}


