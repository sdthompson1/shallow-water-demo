// see graphics.hlsl for more info about this file

#include "graphics.hlsl"

// simplified gamma correction.

float3 ToLinear(float3 srgb)
{
    return pow(abs(srgb), 2.2f);
}

float3 FromLinear(float3 lin)
{
    return pow(abs(lin), 1.0f / 2.2f);
}



// Pixel Shader for Water

float4 WaterPixelShader( WATER_PS_INPUT input ) : SV_Target
{
    // approximate Fresnel factor
    // (this is the percentage that reflects, as opposed to transmits)
    float fresnel = (1-fresnel_coeff) + fresnel_coeff * pow(max(0, 1 - dot(input.eye, input.normal)), fresnel_exponent);
    
    // reflected light
    float3 reflection_dir = reflect(-input.eye, input.normal);
    float3 reflect_col = txSkybox.Sample(samLinear, reflection_dir).rgb;

    //specular
    reflect_col += specular_intensity * pow(max(0,dot(reflection_dir, light_dir)), specular_exponent);

    // refracted light
    float3 refract_col;
    float attenuation_factor;
    float3 refract_dir = refract( -input.eye, input.normal, 1.0f / refractive_index);

    if (refract_dir.z > 0) {
        // refracted ray goes up into the sky
        // (this can only happen with slanted water surfaces)
        // note: we have no way of knowing the distance through the water that the
        // ray has travelled, so we just hard code the attenuation
        refract_col = txSkybox.Sample(samLinear, refract_dir).rgb;
        attenuation_factor = 0.8f;
        
    } else {
        // refracted ray hits the grass
        float dist = -input.water_depth / refract_dir.z;
        float2 base_pos = input.world_pos.xy + dist * refract_dir.xy;
        float2 refract_tex_coord = world_to_grass_tex * base_pos + grass_tex_of_origin;
        refract_col = txGrass.Sample(samLinear, refract_tex_coord).rgb;
        refract_col = TerrainColour(refract_col, input.terrain_normal);  // apply terrain lighting (approximation)
        attenuation_factor = (1-attenuation_1) * exp(-attenuation_2 * dist);
    }
    
    // combine reflection & refraction
    float3 result = FromLinear(lerp(lerp(ToLinear(deep_col),
                                         ToLinear(refract_col),
                                         attenuation_factor),
                                    ToLinear(reflect_col),
                                    fresnel));
    
    return float4(result, 1);
}

