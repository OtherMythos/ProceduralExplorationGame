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
    float3 colour;
};

fragment float4 main_metal
(
    PS_INPUT inPs [[stage_in]],
    constant Params &p [[buffer(PARAMETER_SLOT)]],
    texture2d<float> Image [[texture(0)]],
    sampler samplerState [[sampler(0)]]
)
{
    float4 startValue = OGRE_Sample(Image, samplerState, inPs.uv0);

    if(startValue.w == 0.0){
        returnFinalColour(float4(readUniform(colour), 1.0));
    }else{
        float3 terrainColour = float3(0.1, 0.1, 1.0);

        float alpha = startValue.w;
        float finalAlpha = alpha / (startValue.z);

        float3 targetTerrainColour = terrainColour + float3(startValue.r);
        float3 colValue = mix(readUniform(colour), targetTerrainColour, finalAlpha);

        returnFinalColour(float4(colValue, startValue.z));
    }
}
