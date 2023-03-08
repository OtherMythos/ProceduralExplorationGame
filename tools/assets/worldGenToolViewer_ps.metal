#include <metal_stdlib>
using namespace metal;

struct PS_INPUT
{
	float2 uv0;
};

struct Params
{

};

fragment float4 main_metal
(
	PS_INPUT inPs [[stage_in]],
	texture2d<float>	Image			[[texture(0)]],
	sampler				samplerState	[[sampler(0)]],

	constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{
   float2 uv = inPs.uv0;

   float4 val = Image.sample(samplerState, uv);
   //if(val.x <= 0.5) val = float4(0, 0, 1, 1);
   //else val = float4(0, 1, 0, 1);
   return val;

   //return float4(float3(col1.x, col2.y, col3.z), 1.0);
   //return float4(1.0, 0.0, 0.0, 1.0);
}
