/* -*-c++-*-
 *
 * FILE:
 *   graphics.hlsl
 *
 * PURPOSE:
 *   Graphical shaders for shallow water demo
 *   (land, water, and sky)
 *
 * AUTHOR:
 *   Stephen Thompson <stephen@solarflare.org.uk>
 *
 * CREATED:
 *   24-Oct-2011
 *
 * COPYRIGHT:
 *   Copyright (C) 2012, Stephen Thompson. All rights reserved.
 *
 */

// Textures

// heightfield texture: 3 x 32-bit float
// r = B (height)
// g = dB/dx
// b = dB/dy

Texture2D<float3> txHeightfield : register( t0 );

// grass image texture.
Texture2D<float4> txGrass : register( t0 );

// a linear sampler
SamplerState samLinear : register( s0 );

// skybox cube texture
TextureCube txSkybox : register( t1 );


// water texture: 4 x 32-bit float
// r = w
// g = hu
// b = hv
// a = (unused)

Texture2D<float4> txWater : register( t1 );

// normal texture

// r = nX
// g = nY
// b = nZ
// a = unused

Texture2D<float4> txNormal : register( t2 );



// Constant Buffers

cbuffer MyConstBuffer : register( b0 )
{
    // used by renderer
    row_major float4x4 tex_to_clip;    // transforms (x_tex_idx, y_tex_idx, z_world, 1) to clip space
    float3 light_dir;   // in world space
    float ambient;
    float3 eye_mult, eye_trans;

    float2 terrain_tex_scale;

    // skybox matrix
    row_major float3x3 skybox_mtx;  // transforms world to clip space
    float4 pack;

    // refraction stuff
    float2 world_mult, world_trans;
    float2 world_to_grass_tex;
    float2 grass_tex_of_origin;

    // more settings
    float fresnel_coeff, fresnel_exponent;
    float specular_intensity, specular_exponent;
    float refractive_index;
    float attenuation_1, attenuation_2;
    
    int nx_plus_1, ny_plus_1;
    
    float3 deep_col;

    
};


// Structure definitions

struct VS_INPUT {
    int2 pos : INT_POSITION;       // texture indices
};

struct TERRAIN_PS_INPUT {
    float4 pos : SV_POSITION;      // clip space
    float3 normal : NORMAL;        // world space
    float2 tex_coord : TEXCOORD;
};

struct WATER_PS_INPUT {
    float4 pos : SV_POSITION;      // clip space
    float3 normal : NORMAL;        // world space
    float3 eye : CAMERA_DIRECTION; // world space
    float water_depth : WATER_DEPTH;   // water depth (h) as float
    float2 world_pos : WORLD_XY_POS;   // world space
    float3 terrain_normal : TERRAIN_NORMAL;
};

struct SKYBOX_PS_INPUT {
    float4 pos : SV_POSITION;
    float3 tex : TEXCOORD;
};


// lighting function for terrain.

float3 TerrainColour(float3 tex_colour, float3 terrain_normal)
{
    float light = saturate(dot(light_dir, terrain_normal)) + ambient;
    return light * tex_colour;
}


// SEE ALSO:
// TerrainVertexShader.hlsl
// TerrainPixelShader.hlsl
// WaterVertexShader.hlsl
// WaterPixelShader.hlsl
// SkyboxVertexShader.hlsl
// SkyboxPixelShader.hlsl

