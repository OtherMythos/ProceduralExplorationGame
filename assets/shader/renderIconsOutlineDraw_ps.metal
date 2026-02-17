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

fragment float4 main_metal
(
    PS_INPUT inPs [[stage_in]],
    texture2d<float> Image [[texture(0)]],
    sampler samplerState [[sampler(0)]]
)
{
    float4 centre = OGRE_Sample(Image, samplerState, inPs.uv0);

    float2 texelSize = sizeForTexture(Image);
    float stepX = 1.0 / texelSize.x;
    float stepY = 1.0 / texelSize.y;

    float leftAlpha = OGRE_Sample(Image, samplerState, inPs.uv0 + float2(-stepX, 0)).a;
    float rightAlpha = OGRE_Sample(Image, samplerState, inPs.uv0 + float2(stepX, 0)).a;
    float topAlpha = OGRE_Sample(Image, samplerState, inPs.uv0 + float2(0, -stepY)).a;
    float bottomAlpha = OGRE_Sample(Image, samplerState, inPs.uv0 + float2(0, stepY)).a;

    //If any neighbour has alpha content and the centre is empty, draw an outline.
    float neighbourAlpha = max(max(leftAlpha, rightAlpha), max(topAlpha, bottomAlpha));
    if(centre.a < 0.01 && neighbourAlpha > 0.01){
        returnFinalColour(float4(0, 0, 0, 1));
    }

    returnFinalColour(centre);
}
