/* -*- c++ -*-
 * 
 * FILE:
 *   kp07.hlsl
 *
 * PURPOSE:
 *   HLSL implementation of the Kurganov-Petrova scheme for solving
 *   the 2D shallow water equations. See:
 *
 *   A. Kurganov and G. Petrova, "A Second-Order Well-Balanced
 *   Positivity Preserving Central-Upwind Scheme for the Saint-Venant
 *   System", Commun. Math. Sci. 5, 133-160, 2007.
 *
 * AUTHOR:
 *   Stephen Thompson <stephen@solarflare.org.uk>
 *
 * CREATED:
 *   27-Oct-2011
 *
 * COPYRIGHT:
 *   Copyright (C) 2012, Stephen Thompson. All rights reserved.
 *
 */

cbuffer SimConstBuffer : register( b0 )
{
    // THETA = parameter for minmod limiter. between 1 and 2 inclusive.
    // 1 = more dissipative, 2 = more oscillatory. 1.3 is a good default.
    // (Note: we actually store 2*THETA.)
    float TWO_THETA;

    float two_over_nx_plus_four;
    float two_over_ny_plus_four;

    float g;
    float half_g;
    float g_over_dx;
    float g_over_dy;
    float one_over_dx;
    float one_over_dy;
    float dt;
    float epsilon;      // suggestion: dx^4 or dy^4. but that may be too small for floats?

    int nx, ny;  // number of cells, excluding ghost zones

    float friction;              // m s^-1
};

cbuffer BoundaryConstBuffer : register( b0 )
{
    float boundary_epsilon;
    int reflect_x, reflect_y;
    int solid_wall_flag;
    int inflow_x_min, inflow_x_max;
    float sea_level, inflow_height, inflow_speed;
    float boundary_g;
    float total_time;
    float sa1, skx1, sky1, so1;
    float sa2, skx2, sky2, so2;
    float sa3, skx3, sky3, so3;
    float sa4, skx4, sky4, so4;
    float sdecay;
};

// .r = B(j, k+1/2)   "BN" or "BY"
// .g = B(j+1/2, k)   "BE" or "BX"
// .b = B(j, k)       "BA"
// Note: this is the same size as the main textures i.e. includes ghost zones.
Texture2D<float3> txBottom : register( t1 );

// .r = w_bar
// .g = hu_bar
// .b = hv_bar
// .a = (unused)
Texture2D<float4> txState : register( t0 );

// .r = N
// .g = E
// .b = S
// .a = W
Texture2D<float4> txH : register( t0 );
Texture2D<float4> txU : register( t1 );
Texture2D<float4> txV : register( t2 );

// .r = 1 (w-flux)
// .g = 2 (hu-flux)
// .b = 3 (hv-flux)
// .a = (unused)
Texture2D<float4> txXFlux : register( t2 );
Texture2D<float4> txYFlux : register( t3 );

struct VS_INPUT {
    float2 tex_idx : TEX_IDX;
};

struct VS_OUTPUT {
    float4 pos : SV_POSITION;
    float2 tex_idx : TEX_IDX; // should be cast to integer.
};

struct PASS_1_OUTPUT {
    float4 h : SV_TARGET0;    // {hN, hE, hS, hW}
    float4 u : SV_TARGET1;    // {uN, uE, uS, uW}
    float4 v : SV_TARGET2;    // {vN, vE, vS, vW}
    float4 n : SV_TARGET3;    // {nX, nY, nZ, unused}
};

struct PASS_2_OUTPUT {
    float4 xflux : SV_TARGET0;   // {Hx1, Hx2, Hx3, unused}
    float4 yflux : SV_TARGET1;   // {Hy1, Hy2, Hy3, unused}
};


int3 GetTexIdx(VS_OUTPUT input)
{
    return int3(input.tex_idx.x, input.tex_idx.y, 0);
}

float MinMod(float a, float b, float c)
{
    return (a > 0 && b > 0 && c > 0) ? min(min(a,b),c)
        : (a < 0 && b < 0 && c < 0) ? max(max(a,b),c) : 0;
}

void Reconstruct(float west, float here, float east,
                 out float out_west, out float out_east)
{
    // west, here, east = values of U_bar at j-1, j, j+1 (or k-1, k, k+1)
    // out_west, out_east = reconstructed values of U_west and U_east at (j,k)
    
    float dx_grad_over_two = 0.25f * MinMod(TWO_THETA * (here - west),
                                            (east - west),
                                            TWO_THETA * (east - here));

    out_east = here + dx_grad_over_two;
    out_west = here - dx_grad_over_two;
}

void CorrectW(float B_west, float B_east, float w_bar,
              inout float w_west, inout float w_east)
{
    if (w_east < B_east) {
        w_east = B_east;
        w_west = max(B_west, 2 * w_bar - B_east);
            
    } else if (w_west < B_west) {
        w_east = max(B_east, 2 * w_bar - B_west);
        w_west = B_west;
    }
}              

void CalcUV(float4 h, float4 hu, float4 hv, out float4 u, out float4 v)
{
    // in:  {hN, hE, hS, hW},  {huN, huE, huS, huW},  {hvN, hvE, hvS, hvW}
    // out: {uN, uE, uS, uW},  {vN, vE, vS, vW}
    const float4 h2 = h * h;
    const float4 h4 = h2 * h2;
    const float4 divide_by_h = sqrt(2.0f) * h / sqrt(h4 + max(h4, epsilon));
    u = divide_by_h * hu;
    v = divide_by_h * hv;
}

float CalcUV_Scalar(float h, float hu, float hv, out float u, out float v)
{
    const float h2 = h * h;
    const float h4 = h2 * h2;
    const float divide_by_h = sqrt(2.0f) * h / sqrt(h4 + max(h4, epsilon));
    u = divide_by_h * hu;
    v = divide_by_h * hv;
    return divide_by_h;
}

float CalcU_Boundary(float h, float hu)
{
    const float h2 = h * h;
    const float h4 = h2 * h2;
    const float divide_by_h = sqrt(2.0f) * h / sqrt(h4 + max(h4, boundary_epsilon));
    return divide_by_h * hu;
}

float NumericalFlux(float aplus, float aminus, float Fplus, float Fminus, float Udifference)
{
    if (aplus - aminus > 0) {
        return (aplus * Fminus - aminus * Fplus + aplus * aminus * Udifference) / (aplus - aminus);
    } else {
        return 0;
    }
}


// Boundary condition shaders

// fixed depth boundary calculation for east/north boundary
// returns h and hu for ghost zone (hv_ghost = 0).
void FixedHBoundary(float h_desired,
                    float h_real, float hu_real,
                    out float h_ghost, out float hu_ghost)
{
    float u_real = CalcU_Boundary(h_real, hu_real);
    float c_real = sqrt(boundary_g * h_real);
    float c_desired = sqrt(boundary_g * h_desired);
    float c_ghost = -u_real/2 - c_real + 2 * c_desired;

    if (c_ghost < 0) {
        h_ghost = 0;
        hu_ghost = hu_real + h_real * (2 * c_real - 4 * c_desired);
    } else {
        const float LIMIT = 2.0f;
        h_ghost = min(h_real + LIMIT, c_ghost*c_ghost / boundary_g);
        hu_ghost = 0;
    }
}    

float CalcSeaLevel( float2 tex_idx)
{
    return sea_level + (sa1 * cos(skx1 * tex_idx.x + sky1 * tex_idx.y - so1 * total_time)
                        + sa2 * cos(skx2 * tex_idx.x + sky2 * tex_idx.y - so2 * total_time)
                        + sa3 * cos(skx3 * tex_idx.x + sky3 * tex_idx.y - so3 * total_time)
                        + sa4 * cos(skx4 * tex_idx.x + sky4 * tex_idx.y - so4 * total_time)
                        ) * exp(-sdecay * tex_idx.y);
}
