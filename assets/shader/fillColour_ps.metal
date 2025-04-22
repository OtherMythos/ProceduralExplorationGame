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
    float4 colour;
};

fragment float4 main_metal
(
    PS_INPUT inPs [[stage_in]],
    constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{
    returnFinalColour(p.colour);
}
