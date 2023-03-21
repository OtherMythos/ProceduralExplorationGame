#include <metal_stdlib>
using namespace metal;

struct PS_INPUT
{
	float2 uv0;
};

struct Params
{
   //Make it a bit bigger than needed to test things.
   unsigned int intBuffer[1000*1000];
   unsigned int riverBuffer[3000];
   unsigned int placeBuffer[1000];
   int width;
   int height;
   unsigned int drawFlags;
   unsigned int numWaterSeeds;
   unsigned int numLandSeeds;
   unsigned int seaLevel;
};

fragment float4 main_metal
(
	PS_INPUT inPs [[stage_in]],

	constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{

   int WATER_MASK = 1 << 0;
   int GROUND_MASK = 1 << 1;
   int WATER_GROUPS_MASK = 1 << 2;
   int RIVER_DATA_MASK = 1 << 3;
   int LAND_GROUPS_MASK = 1 << 4;
   int EDGE_VALS = 1 << 5;
   int PLACE_LOCATIONS = 1 << 6;

   float4 voxelColours[] = {
      float4(0.84, 0.87, 0.29, 1),
      float4(0.33, 0.92, 0.27, 1),
      float4(0.84, 0.88, 0.84, 1),
   };

   float2 uv = inPs.uv0;
   unsigned int xVox = (int)(uv.x * p.width);
   unsigned int yVox = (int)(uv.y * p.height);

   int voxVal = p.intBuffer[xVox + yVox * p.width];
   short altitude = voxVal & 0xFF;
   short voxelMeta = (voxVal >> 8) & 0x7F;
   short edgeVox = (voxVal >> 8) & 0x80;
   short waterGroup = (voxVal >> 16) & 0xFF;
   short landGroup = (voxVal >> 24) & 0xFF;

   float4 drawVal(0, 0, 0, 1);

   //Just draw the altitude.
   float val = (float)altitude / 255;
   drawVal = float4(val, val, val, 1);

   if(p.drawFlags & GROUND_MASK){
      drawVal = voxelColours[voxelMeta];
   }
   if(p.drawFlags & WATER_MASK){
      if(altitude < p.seaLevel){
         if(waterGroup == 0){
            drawVal = float4(0, 0, 1.0, 1.0);
         }else{
            drawVal = float4(0.15, 0.15, 1.0, 1.0);
         }
      }
   }
   if(p.drawFlags & WATER_GROUPS_MASK){
      float valGroup = (float)waterGroup / p.numWaterSeeds;
      drawVal = float4(valGroup, valGroup, valGroup, 1);
   }
   if(p.drawFlags & RIVER_DATA_MASK){
      //for(int i = 0; i < 4; i++){
      int i = 0;
      bool first = true;
      while(true){
         unsigned int riverVal = p.riverBuffer[i];
         if(first && riverVal == 0xFFFFFFFF){
            break;
         }
         unsigned int x = (riverVal >> 16) & 0xFFFF;
         unsigned int y = riverVal & 0xFFFF;
         if(xVox == x && yVox == y){
            drawVal = first ? float4(1, 0, 1, 1) : float4(1, 1, 1, 1);
         }
         first = false;
         i++;
         if(riverVal == 0xFFFFFFFF){
            first = true;
         }
      }
   }
   if(p.drawFlags & LAND_GROUPS_MASK){
      float valGroup = (float)landGroup / p.numLandSeeds;
      drawVal = float4(valGroup, valGroup, valGroup, 1);
   }
   if(p.drawFlags & EDGE_VALS){
      if(edgeVox){
         drawVal = float4(0, 0, 0, 1);
      }
   }
   if(p.drawFlags & PLACE_LOCATIONS){
      int i = 0;
      while(true){
         unsigned int placeVal = p.placeBuffer[i];
         if(placeVal == 0xFFFFFFFF) break;

         unsigned int x = (placeVal >> 16) & 0xFFFF;
         unsigned int y = placeVal & 0xFFFF;
         if(xVox == x && yVox == y){
            drawVal = float4(0, 0, 0, 1);
            break;
         }
         i++;
      }
   }

   return drawVal;
}
