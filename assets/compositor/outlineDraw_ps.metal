#include <metal_stdlib>
using namespace metal;

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


float linearizeDepthStub(constant Params& p, float depth)
{
    return depth;
}
float linearizeDepth(constant Params& p, float depth)
{
    //float z = depth * 2.0 - 1.0;
    //return (2.0 * p.near * p.far) / (p.far + p.near - z * (p.far - p.near));

    return p.near * p.far / (p.far - depth * (p.far - p.near));

    //return depth;
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
    float2 texelSize = float2(Depth.get_width(), Depth.get_height());
    float stepX = 1.0 / texelSize.x;
    float stepY = 1.0 / texelSize.y;

    // Sample depth values
    float dCenter    = Depth.sample(DepthSampler, inPs.uv0).x;
    float dLeft      = Depth.sample(DepthSampler, inPs.uv0 + float2(-stepX, 0)).x;
    float dRight     = Depth.sample(DepthSampler, inPs.uv0 + float2(stepX, 0)).x;
    float dTop       = Depth.sample(DepthSampler, inPs.uv0 + float2(0, -stepY)).x;
    float dBottom    = Depth.sample(DepthSampler, inPs.uv0 + float2(0, stepY)).x;

    const float epsilon = 1e-4; // Small bias to prevent artifacts
    float edge = 0.0;
    edge += abs(dCenter - dLeft) > epsilon ? abs(dCenter - dLeft) : 0.0;
    edge += abs(dCenter - dRight) > epsilon ? abs(dCenter - dRight) : 0.0;
    edge += abs(dCenter - dTop) > epsilon ? abs(dCenter - dTop) : 0.0;
    edge += abs(dCenter - dBottom) > epsilon ? abs(dCenter - dBottom) : 0.0;
    edge *= 50;

    float edgeFactor = step(p.edgeThreshold, edge);

    //return float4(edge, edge, edge, 1.0);
    //return float4(dCenter, dCenter, dCenter, 1.0);
    //return float4(inPs.uv0.x, inPs.uv0.x, inPs.uv0.x, 1.0);
    //float3 edgeColor = float3(1, 1, 1);
    //return mix(float4(0.0), float4(edgeColor, 1.0), edgeFactor);
    //return float4(edgeFactor, edgeFactor, edgeFactor, 1.0);
    return mix(Image.sample(samplerState, inPs.uv0), float4(0, 0, 0, 1.0), edgeFactor);
}
