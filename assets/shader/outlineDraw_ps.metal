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

    float maxVal =
        max(yCenter,
        max(yLeft,
        max(yRight,
        max(yTop,
        yBottom
    ))));

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

    float edge = 0.0;
    edge += abs(xCenter - xLeft);
    edge += abs(xCenter - xRight);
    edge += abs(xCenter - xTop);
    edge += abs(xCenter - xBottom);
    edge *= 50;

    float edgeThreshold = 0.005;
    float edgeFactor = step(edgeThreshold, edge);
    return edgeFactor;
}

float2 computeLineForImage(float2 uv0, texture2d<float> image, sampler imageSampler){
    float2 texelSize = sizeForTexture(image);
    float stepX = 1.0 / texelSize.x;
    float stepY = 1.0 / texelSize.y;

    float4 Center = OGRE_Sample( image, imageSampler, uv0);
    float4 Left      = OGRE_Sample( image, imageSampler, uv0 + float2(-stepX, 0));
    float4 Right     = OGRE_Sample( image, imageSampler, uv0 + float2(stepX, 0));
    float4 Top       = OGRE_Sample( image, imageSampler, uv0 + float2(0, -stepY));
    float4 Bottom    = OGRE_Sample( image, imageSampler, uv0 + float2(0, stepY));

    float edgeFactor = calculateEdgeFactor(Center, Left, Right, Top, Bottom);
    float edgeStrength = 0.0;
    if(edgeFactor != 0.0){
        edgeStrength = calculateLineStrengthForDistance(Center, Left, Right, Top, Bottom);
    }

    return float2(edgeFactor, edgeStrength);
}

fragment float4 main_metal
(
    PS_INPUT inPs [[stage_in]],
    texture2d<float> Image [[texture(0)]],
    texture2d<float> Depth [[texture(1)]],
    texture2d<float> SecondaryImage [[texture(2)]],
    sampler samplerState [[sampler(0)]],
    sampler DepthSampler [[sampler(1)]],
    sampler SecondaryImageSampler [[sampler(2)]],

    constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{

    float4 startValue = OGRE_Sample( Image, samplerState, inPs.uv0 );

    float4 Center = OGRE_Sample( Depth, DepthSampler, inPs.uv0);
    if(Center.x == 0){
        returnFinalColour(startValue);
    }

    float2 mainOutline = computeLineForImage(inPs.uv0, Depth, DepthSampler);
    if(mainOutline.x != 0.0 && mainOutline.y != 0.0){
        startValue = mix(startValue, float4(0, 0, 0, 1), mainOutline.x * mainOutline.y);
        returnFinalColour(startValue);
    }

    float2 innerOutline = computeLineForImage(inPs.uv0, SecondaryImage, SecondaryImageSampler);
    startValue = mix(startValue, float4(0.25, 0.25, 0.25, 1), innerOutline.x * innerOutline.y * 0.3);
    returnFinalColour(startValue);
}
