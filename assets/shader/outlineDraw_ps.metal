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

float calculateLineStrengthForDistance(float4 Center, float4 Left, float4 Right, float4 Top, float4 Bottom){
    float yCenter = Center.y;
    float yLeft      = Left.y;
    float yRight     = Right.y;
    float yTop       = Top.y;
    float yBottom    = Bottom.y;

    constexpr int count = 5;
    float values[count] = {yCenter, yLeft, yRight, yTop, yBottom};
    float maxVal = values[0];
    for (int i = 1; i < count; ++i) {
        maxVal = max(maxVal, values[i]);
    }

    maxVal *= 1000;
    maxVal = clamp(maxVal, 0.0, 1.0);
    maxVal = pow(maxVal, 4);
    float colVal = maxVal;

    colVal = clamp(colVal, 0.4, 1.0);

    return colVal;
}

float calculateEdgeFactor(float4 Center, float4 Left, float4 Right, float4 Top, float4 Bottom){
    float xCenter = Center.x;
    float xLeft = Left.x;
    float xRight = Right.x;
    float xTop = Top.x;
    float xBottom = Bottom.x;

    const float epsilon = 1e-4; // Small bias to prevent artifacts
    float edge = 0.0;
    edge += abs(xCenter - xLeft) > epsilon ? abs(xCenter - xLeft) : 0.0;
    edge += abs(xCenter - xRight) > epsilon ? abs(xCenter - xRight) : 0.0;
    edge += abs(xCenter - xTop) > epsilon ? abs(xCenter - xTop) : 0.0;
    edge += abs(xCenter - xBottom) > epsilon ? abs(xCenter - xBottom) : 0.0;
    edge *= 50;

    float edgeThreshold = 0.005;
    float edgeFactor = step(edgeThreshold, edge);
    return edgeFactor;
}

fragment float4 main_metal
(
    PS_INPUT inPs [[stage_in]],
    texture2d<float> Image [[texture(0)]],
    texture2d<float> Depth [[texture(1)]],
    sampler samplerState [[sampler(0)]],
    sampler DepthSampler [[sampler(1)]],

    constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{
    float2 texelSize = sizeForTexture(Depth);
    float stepX = 1.0 / texelSize.x;
    float stepY = 1.0 / texelSize.y;

    // Sample depth values
    float4 Center = OGRE_Sample( Depth, DepthSampler, inPs.uv0);
    float4 Left      = OGRE_Sample( Depth, DepthSampler, inPs.uv0 + float2(-stepX, 0));
    float4 Right     = OGRE_Sample( Depth, DepthSampler, inPs.uv0 + float2(stepX, 0));
    float4 Top       = OGRE_Sample( Depth, DepthSampler, inPs.uv0 + float2(0, -stepY));
    float4 Bottom    = OGRE_Sample( Depth, DepthSampler, inPs.uv0 + float2(0, stepY));

    float edgeStrength = calculateLineStrengthForDistance(Center, Left, Right, Top, Bottom);
    float edgeFactor = calculateEdgeFactor(Center, Left, Right, Top, Bottom);

    returnFinalColour(mix(OGRE_Sample( Image, samplerState, inPs.uv0 ) , float4(0, 0, 0, 1), edgeFactor * edgeStrength));
}
