#include <metal_stdlib>
using namespace metal;

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
    float amount;
};

fragment float4 main_metal
(
    PS_INPUT inPs [[stage_in]],
    constant Params &p [[buffer(PARAMETER_SLOT)]],
    texture2d<float> Image [[texture(0)]],
    sampler samplerState [[sampler(0)]]
)
{
    float2 uv = inPs.uv0;

    float anim = (1 - pow(1 - p.amount, 2));
    //float anim = p.amount;

    // Recenter to [-1,1] space
    float2 centered = uv * 2.0 - 1.0;

    // Get texture size and compute aspect ratio
    float2 texSize = sizeForTexture(Image);
    float aspect = texSize.x / texSize.y;

    // Correct for aspect ratio so gradient is circular
    //centered.x *= (texSize.y / texSize.x);

    // Compute distance from center
    float dist = length(centered);

    // Smooth falloff for blending (tweak 0.5, 1.0 for softness/extent)
    float val = smoothstep(0.4, 2.0, dist);

    // Sample the original texture
    float4 startValue = OGRE_Sample(Image, samplerState, uv);

    // Mix with red based on gradient
    float4 result = mix(startValue, float4(1, 0, 0, 1), val * anim);

    returnFinalColour(result);
}
