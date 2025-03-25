/* -*- c++ -*-
 *
 * FILE:
 *   left_mouse.hlsl
 *
 * PURPOSE:
 *   Shaders for the left mouse button effects (add/remove water, etc)
 *
 * AUTHOR:
 *   Stephen Thompson <stephen@solarflare.org.uk>
 *
 * CREATED:
 *   9-Nov-2011
 *
 * COPYRIGHT:
 *   Copyright (C) 2012, Stephen Thompson. All rights reserved.
 *
 */

cbuffer LeftMouseConstBuffer : register( b0 )
{
    float2 scale;
    float2 bias;

    float two_over_nx_plus_four;
    float two_over_ny_plus_four;

    float disp_A, disp_B;   // control the amount to add or subtract from the water height.
};

// .r = w_bar
// (This is a COPY of the current state, because we can't read from the buffer we are writing to)
Texture2D<float4> txState : register( t0 );

// .b = B_average
Texture2D<float3> txBottom : register( t1 );

struct VS_INPUT {
    float2 pos : POSITION;   // Position in "brush space" (centre (0,0), radius 1)
};

struct VS_OUTPUT {
    float4 pos : SV_POSITION;
    float2 tex_idx : TEX_IDX;  // should be cast to an integer by the pixel shader
    float radius : RADIUS;
};

// SEE ALSO:
// LeftMouseVertexShader.hlsl
// LeftMousePixelShader.hlsl

