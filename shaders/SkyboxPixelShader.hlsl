// see graphics.hlsl for more info about this file

#include "graphics.hlsl"

float4 SkyboxPixelShader( SKYBOX_PS_INPUT input ) : SV_TARGET
{
    // tex lookup
    return txSkybox.Sample(samLinear, input.tex);
}
