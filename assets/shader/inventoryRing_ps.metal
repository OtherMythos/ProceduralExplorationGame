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
    float radian;
};

fragment float4 main_metal
(
    PS_INPUT inPs [[stage_in]],
    constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{
    float suppliedRadian = M_PI_F * 2 - 0.2;

    float2 delta = inPs.uv0 - float2(0.5, 0.5);
    float dist = length(delta); // use actual distance, easier for outline thickness

    float outer = 0.5;
    float inner = 0.38;
    float outline = 0.02; // outline thickness in UV units

    if(dist <= outer && dist >= inner) {
        float4 targetCol = float4(0, 0, 0, 0.2); // default = outline

        // inside the "fill" part, away from outline
        if(dist >= inner + outline && dist <= outer - outline) {
            targetCol = float4(p.colour, 1);
        }

        // Angle measured clockwise from top (north)
        float angle = atan2(delta.x, -delta.y);
        if(angle < 0.0) angle += 2.0 * M_PI_F;

        if(angle <= p.radian) {
            returnFinalColour(targetCol);
        }
    }

    if(dist <= outer && dist >= inner) {
        float4 targetCol = float4(0, 0, 0, 0.2); // default = outline

        // inside the "fill" part, away from outline
        if(dist >= inner + outline && dist <= outer - outline) {
            targetCol = float4(p.colour, 1);
        }

        // Angle measured clockwise from top (north)
        float angle = atan2(delta.x, -delta.y);
        if(angle < 0.0) angle += 2.0 * M_PI_F;

        if(angle <= p.radian) {
            returnFinalColour(targetCol);
        }
    }

    returnFinalColour(float4(0, 0, 0, 0));
}
