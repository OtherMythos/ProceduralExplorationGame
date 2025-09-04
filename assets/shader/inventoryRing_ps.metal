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
    float suppliedRadian = M_PI_F * 2 - 0.2;

    float2 delta = inPs.uv0 - float2(0.5, 0.5);
    float dist2 = dot(delta, delta);

    float outer = 0.5;
    float inner = 0.38;

    if(dist2 <= outer * outer && dist2 >= inner * inner) {
        // Angle measured clockwise from top (north)
        float angle = atan2(delta.x, -delta.y);
        if(angle < 0.0) angle += 2.0 * M_PI_F;

        float cutoff = suppliedRadian; // arc length in radians, clockwise from top

        if(angle <= cutoff) {
            returnFinalColour(float4(1, 1, 1, 1)); // visible arc
        }
    }

    returnFinalColour(float4(0, 0, 0, 0));
}
