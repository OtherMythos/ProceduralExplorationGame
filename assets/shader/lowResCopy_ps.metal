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
    float near;
    float far;
    float edgeThreshold;
};

fragment float4 main_metal
(
    PS_INPUT inPs [[stage_in]],
    texture2d<float> First [[texture(0)]],
    texture2d<float> Second [[texture(1)]],
    sampler firstSampler [[sampler(0)]],
    sampler secondSampler [[sampler(1)]],

    constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{
    float4 f = OGRE_Sample(First, firstSampler, inPs.uv0);
    float4 s = OGRE_Sample(Second, secondSampler, inPs.uv0);

    returnFinalColour(mix(f, float4(1, 1, 1, 1), 0.5 * s.x));
}
