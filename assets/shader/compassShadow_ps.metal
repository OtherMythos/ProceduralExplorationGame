#include <metal_stdlib>
using namespace metal;


//----------------------------------------------------------

#define sizeForTexture( x ) float2(x.get_width(), x.get_height())
#define OGRE_Sample( tex, sampler, uv ) tex.sample( sampler, uv )

#define readUniform( x ) p.x

#define returnFinalColour( x ) return x
//----------------------------------------------------------

struct PS_INPUT
{
    float2 uv0;
};

struct Params
{
};

fragment float4 main_metal
(
    PS_INPUT inPs [[stage_in]],
    constant Params &p [[buffer(PARAMETER_SLOT)]],
    texture2d<float> Image [[texture(0)]],
    sampler samplerState [[sampler(0)]]
)
{
    float2 texSize     = sizeForTexture(Image);
    float2 texelOffset = 1.0 / texSize;

    float4 center = OGRE_Sample(Image, samplerState, inPs.uv0);

    // If center pixel is white, just draw it
    if (center.a > 0.5 && all(center.rgb > float3(0.9)))
    {
        returnFinalColour(center);
    }

    // Otherwise, check the 8 surrounding pixels explicitly
    bool outline = false;

    float2 uv;
    float4 checkVal = float4(0.9,0.9,0.9,0.5);

    // left
    uv = inPs.uv0 + float2(-texelOffset.x, 0);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    // right
    uv = inPs.uv0 + float2(texelOffset.x, 0);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    // up
    uv = inPs.uv0 + float2(0, -texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    // down
    uv = inPs.uv0 + float2(0, texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

/*
    // diagonals
    uv = inPs.uv0 + float2(-texelOffset.x, -texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    uv = inPs.uv0 + float2(texelOffset.x, -texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    uv = inPs.uv0 + float2(-texelOffset.x, texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    uv = inPs.uv0 + float2(texelOffset.x, texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;
*/

    if (outline)
    {
        returnFinalColour(float4(0,0,0,0.5));
    }

    returnFinalColour(float4(0,0,0,0));
}
