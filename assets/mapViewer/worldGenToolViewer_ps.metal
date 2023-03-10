#include <metal_stdlib>
using namespace metal;

struct PS_INPUT
{
	float2 uv0;
};

struct Params
{
   //Make it a bit bigger than needed to test things.
   float testBuffer[1000*1000];
   int width;
   int height;
};

fragment float4 main_metal
(
	PS_INPUT inPs [[stage_in]],

	constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{

   float2 uv = inPs.uv0;
   int xVox = (int)(uv.x * p.width);
   int yVox = (int)(uv.y * p.height);

   float val = p.testBuffer[xVox + yVox * p.width];
   return float4(val, val, val, 1);
}
