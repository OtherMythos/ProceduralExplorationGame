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

bool allEqual(float a, float b, float c, float d, float e) {
    float4 v1 = float4(a, b, c, d);
    float4 v2 = float4(e); // All components = e

    // Compare v1 == v2, returns a bool4
    bool4 cmp = (v1 == v2);

    // Reduce to a single bool
    return all(cmp) && (a == e);
}

float2 computeLineForImage(float center, float left, float right, float top, float bottom, bool inner){

    bool edgeFactor = false;
    if(inner){
        edgeFactor = !allEqual(left, right, top, bottom, center);
    }else{
        edgeFactor = (center + left + right + top + bottom) < 5;
    }
    float edgeStrength = 0.0;
    if(edgeFactor){
        //edgeStrength = calculateLineStrengthForDistance(center, left, right, top, bottom);
        edgeStrength = 1.0;
    }

    return float2(float(edgeFactor), edgeStrength);
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

    float4 startValue = OGRE_Sample( Image, samplerState, inPs.uv0 );
    float4 Center = OGRE_Sample( Depth, DepthSampler, inPs.uv0);

    if(Center.x == 0){
        returnFinalColour(startValue);
    }

    float2 texelSize = sizeForTexture(Depth);
    float stepX = 1.0 / texelSize.x;
    float stepY = 1.0 / texelSize.y;

    float4 Left      = OGRE_Sample( Depth, DepthSampler, inPs.uv0 + float2(-stepX, 0));
    float4 Right     = OGRE_Sample( Depth, DepthSampler, inPs.uv0 + float2(stepX, 0));
    float4 Top       = OGRE_Sample( Depth, DepthSampler, inPs.uv0 + float2(0, -stepY));
    float4 Bottom    = OGRE_Sample( Depth, DepthSampler, inPs.uv0 + float2(0, stepY));

    float2 mainOutline = computeLineForImage(Center.x, Left.x, Right.x, Top.x, Bottom.x, false);
    if(mainOutline.x != 0.0 && mainOutline.y != 0.0){
        startValue = mix(startValue, float4(0, 0, 0, 1), mainOutline.x * mainOutline.y);
        returnFinalColour(startValue);
    }

    float2 innerOutline = computeLineForImage(Center.z, Left.z, Right.z, Top.z, Bottom.z, true);
    startValue = mix(startValue, float4(0.25, 0.25, 0.25, 1), innerOutline.x * innerOutline.y * 0.3);
    returnFinalColour(startValue);
}
