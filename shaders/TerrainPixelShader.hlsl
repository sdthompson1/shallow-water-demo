// see graphics.hlsl for more info about this file

#include "graphics.hlsl"


// Pixel Shader for Terrain

float4 TerrainPixelShader( TERRAIN_PS_INPUT input ) : SV_Target
{
    // tex lookup
    float3 tex_colour = txGrass.Sample( samLinear, input.tex_coord ).rgb;
    
    // Lighting calculation
    return float4(TerrainColour(tex_colour, input.normal), 1);
}
