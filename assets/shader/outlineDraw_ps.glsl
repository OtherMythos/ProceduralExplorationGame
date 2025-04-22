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

vulkan_layout( location = 0 )
out vec4 fragColour;

vulkan_layout( location = 0 )
in block
{
    vec2 uv0;
} inPs;

vulkan_layout( ogre_t0 ) uniform texture2D Image;
vulkan_layout( ogre_t1 ) uniform texture2D Depth;
vulkan_layout( ogre_t2 ) uniform texture2D SecondaryImage;

vulkan( layout( ogre_s0 ) uniform sampler samplerState; )
vulkan( layout( ogre_s1 ) uniform sampler DepthSampler; )
vulkan( layout( ogre_s2 ) uniform sampler SecondaryImageSampler; )

vulkan( layout( ogre_P0 ) uniform params { )
    uniform float near;
    uniform float far;
    uniform float edgeThreshold;
vulkan( }; )

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

float2 computeLineForImage(float2 uv0, texture2D image vk_comma vulkan(sampler imageSampler) ){
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

void main()
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
