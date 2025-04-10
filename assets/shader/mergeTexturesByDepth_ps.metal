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
    texture2d<float> FirstDepth [[texture(2)]],
    texture2d<float> SecondDepth [[texture(3)]],
    sampler firstSampler [[sampler(0)]],
    sampler secondSampler [[sampler(1)]],
    sampler firstDepthSampler [[sampler(2)]],
    sampler secondDepthSampler [[sampler(3)]],

    constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{
    float4 f = OGRE_Sample(First, firstSampler, inPs.uv0);
    float4 s = OGRE_Sample(Second, secondSampler, inPs.uv0);

    float fd = OGRE_Sample(FirstDepth, firstDepthSampler, inPs.uv0).x;
    float sd = OGRE_Sample(SecondDepth, secondDepthSampler, inPs.uv0).x;

    if(fd >= sd){
        returnFinalColour(f);
    }else{
        returnFinalColour(s);
    }

}
