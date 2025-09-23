#version ogre_glsl_ver_330

//----------------------------------------------------------
#define float2 vec2
#define float3 vec3
#define float4 vec4

#define int2 ivec2
#define int3 ivec3
#define int4 ivec4

#define uint2 uvec2
#define uint3 uvec3
#define uint4 uvec4

#define float2x2 mat2
#define float3x3 mat3
#define float4x4 mat4

#define ushort uint

#define toFloat3x3( x ) mat3( x )
#define buildFloat3x3( row0, row1, row2 ) mat3( row0, row1, row2 )

#define mul( x, y ) ((x) * (y))
#define saturate(x) clamp( (x), 0.0, 1.0 )
#define lerp mix
#define rsqrt inversesqrt
#define INLINE

#define sizeForTexture( x ) textureSize( x , 0 )

#define finalDrawId drawId
#define PARAMS_ARG_DECL
#define PARAMS_ARG

#define readUniform( x ) x
#define returnFinalColour( x ) fragColour = ( x ); return;

#define outVs_Position gl_Position
#define OGRE_Sample( tex, sampler, uv ) texture( vkSampler2D(tex, sampler), uv )
#define OGRE_SampleLevel( tex, sampler, uv, lod ) textureLod( tex, uv.xy, lod )
#define OGRE_SampleArray2D( tex, sampler, uv, arrayIdx ) texture( tex, vec3( uv, arrayIdx ) )
#define OGRE_SampleArray2DLevel( tex, sampler, uv, arrayIdx, lod ) textureLod( tex, vec3( uv, arrayIdx ), lod )
#define OGRE_SampleGrad( tex, sampler, uv, ddx, ddy ) textureGrad( tex, uv, ddx, ddy )
#define OGRE_SampleArray2DGrad( tex, sampler, uv, arrayIdx, ddx, ddy ) textureGrad( tex, vec3( uv, arrayIdx ), ddx, ddy )
#define OGRE_ddx( val ) dFdx( val )
#define OGRE_ddy( val ) dFdy( val )
//----------------------------------------------------------

#define M_PI_F 3.1415926535897932384626433832795
#define atan2 atan

vulkan_layout( location = 0 )
out vec4 fragColour;

vulkan( layout( ogre_P0 ) uniform params { )
vulkan( }; )

vulkan_layout( location = 0 )
in block
{
    vec2 uv0;
} inPs;

vulkan_layout( ogre_t0 ) uniform texture2D Image;
vulkan( layout( ogre_s0 ) uniform sampler samplerState; )

void main()
{
    float2 texSize     = sizeForTexture(Image);
    float2 texelOffset = 1.0 / texSize;

    float4 center = OGRE_Sample(Image, samplerState, inPs.uv0);

    // If center pixel is white, just draw it
    if (center.a > 0.5 && all(center.rgb > float3(0.9)))
    {
        returnFinalColour(center);
    }

    // Otherwise, check the 8 surrounding pixels explicitly
    bool outline = false;

    float2 uv;
    float4 checkVal = float4(0.9,0.9,0.9,0.5);

    // left
    uv = inPs.uv0 + float2(-texelOffset.x, 0);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    // right
    uv = inPs.uv0 + float2(texelOffset.x, 0);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    // up
    uv = inPs.uv0 + float2(0, -texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    // down
    uv = inPs.uv0 + float2(0, texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

/*
    // diagonals
    uv = inPs.uv0 + float2(-texelOffset.x, -texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    uv = inPs.uv0 + float2(texelOffset.x, -texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    uv = inPs.uv0 + float2(-texelOffset.x, texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;

    uv = inPs.uv0 + float2(texelOffset.x, texelOffset.y);
    if (all(OGRE_Sample(Image, samplerState, uv).rgba > checkVal)) outline = true;
*/

    if (outline)
    {
        returnFinalColour(float4(0,0,0,1));
    }

    returnFinalColour(float4(0,0,0,0));
}
