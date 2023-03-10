#include <metal_stdlib>
using namespace metal;

struct PS_INPUT
{
	float2 uv0;
};

struct Params
{
   float testBuffer[500*500];
};

float getHeightForVal(float2 uv, float input){
   float2 origin(0.5, 0.5);
   float centreOffset = (sqrt(powr(origin.x - uv.x, 2) + powr(origin.y - uv.y, 2)) + 0.1);
   //float curvedOffset = powr(1 - centreOffset, 2) / 2;
   float curvedOffset = centreOffset == 1 ? 1 : 1 - powr(2, -10 * centreOffset);
   curvedOffset = 1.0 - curvedOffset;
   curvedOffset *= 1;
   //float val = curvedOffset;
   float val = (1-centreOffset) * input;   
   val *= 1.5;

   val += curvedOffset*0.8;

   return val;
}

fragment float4 main_metal
(
	PS_INPUT inPs [[stage_in]],

	constant Params &p [[buffer(PARAMETER_SLOT)]] 
)
{

   float2 uv = inPs.uv0;
   int boxSize = 5;
   int boxesWidth = 500;
   int boxesHeight = 500;
   int pointWidth = boxSize * boxesWidth;
   int pointHeight = boxSize * boxesHeight;
	

   int xVox = (int)(uv.x * pointWidth) / boxSize;
   int yVox = (int)(uv.y * pointHeight) / boxSize;
   float testVoxX = (float)xVox / boxesWidth;
   float testVoxY = (float)yVox / boxesHeight;
   float voxVal = testVoxX * testVoxY;

   float val = p.testBuffer[xVox + yVox * boxesWidth];
   return float4(val, val, val, 1);
	/*
	if(p.testBuffer[0] == 1) return float4(1, 1, 1, 1);

   float2 uv = inPs.uv0;
   float worldVal = Image.sample(samplerState, uv).x;
   int boxSize = 5;
   int boxesWidth = 50;
   int boxesHeight = 100;
   int pointWidth = boxSize * boxesWidth;
   int pointHeight = boxSize * boxesHeight;

   float val = getHeightForVal(uv, worldVal);

   if(val <= 0.5) return float4(0, 0, 1, 1);
   else return float4(0, 1, 0, 1);

   //Convert into voxels
   int xVox = (int)(uv.x * pointWidth) / boxSize;
   int yVox = (int)(uv.y * pointHeight) / boxSize;
   float testVoxX = (float)xVox / boxesWidth;
   float testVoxY = (float)yVox / boxesHeight;
   float voxVal = testVoxX * testVoxY;
   return float4(voxVal, voxVal, voxVal, 1);

*/


   //return float4(float3(col1.x, col2.y, col3.z), 1.0);
   //return float4(1.0, 0.0, 0.0, 1.0);
}
