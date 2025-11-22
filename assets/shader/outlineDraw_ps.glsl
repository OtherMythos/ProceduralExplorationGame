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
vulkan_layout( ogre_t2 ) uniform texture2D Wind;
vulkan_layout( ogre_t3 ) uniform texture2D ShadowFirst;
vulkan_layout( ogre_t4 ) uniform texture2D ShadowSecond;

vulkan( layout( ogre_s0 ) uniform sampler samplerState; )
vulkan( layout( ogre_s1 ) uniform sampler DepthSampler; )
vulkan( layout( ogre_s2 ) uniform sampler WindSampler; )
vulkan( layout( ogre_s3 ) uniform sampler ShadowFirstSampler; )
vulkan( layout( ogre_s4 ) uniform sampler ShadowSecondSampler; )

float calculateLineStrengthForDistance(float distance){

    float outDistance = distance / 1000.0;
    outDistance = clamp(outDistance, 0.0, 1.0);
    outDistance = 1.0 - outDistance;
    outDistance = pow(outDistance, 4);
    outDistance = clamp(outDistance, 0.4, 1.0);

    return outDistance;
}

bool allEqual(float a, float b, float c, float d, float e) {
    vec4 v1 = vec4(a, b, c, d);
    vec4 v2 = vec4(e); // All components = e

    // Compare v1 == v2, returns a bvec4
    bvec4 cmp = equal(v1, v2);

    // Reduce to a single bool
    return all(cmp) && (a == e);
}

float2 computeLineForImage(float center, float left, float right, float top, float bottom, float distance, bool inner){

    bool edgeFactor = false;
    if(inner){
        edgeFactor = !allEqual(left, right, top, bottom, center);
    }else{
        //Really check for 5.0, but some drivers had floating point precision issues.
        edgeFactor = (center + left + right + top + bottom) < 4.9;
    }
    float edgeStrength = 0.0;
    if(edgeFactor){
        edgeStrength = calculateLineStrengthForDistance(distance);
    }

    return float2(float(edgeFactor), edgeStrength);
}

void main()
{
    float4 startValue = OGRE_Sample( Image, samplerState, inPs.uv0 );
    float4 Center = OGRE_Sample( Depth, DepthSampler, inPs.uv0);
    float4 WindValue = OGRE_Sample( Wind, WindSampler, inPs.uv0);

    startValue = mix(startValue, float4(1, 1, 1, 1), 0.5 * WindValue.x);

    float4 secondShadow = OGRE_Sample( ShadowSecond, ShadowSecondSampler, inPs.uv0);

    if(secondShadow.x > 0.1){
        float4 firstShadow = OGRE_Sample( ShadowFirst, ShadowFirstSampler, inPs.uv0);
        if(firstShadow.x < 0.1){
            startValue = mix(startValue, float4(0, 0, 0, 1), 0.5);
        }
    }

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

    float2 mainOutline = computeLineForImage(Center.x, Left.x, Right.x, Top.x, Bottom.x, Center.y, false);
    if(mainOutline.x != 0.0 && mainOutline.y != 0.0){
        startValue = mix(startValue, float4(0, 0, 0, 1), mainOutline.x * mainOutline.y);
        returnFinalColour(startValue);
    }

    float2 innerOutline = computeLineForImage(Center.z, Left.z, Right.z, Top.z, Bottom.z, Center.y, true);
    startValue = mix(startValue, float4(0.25, 0.25, 0.25, 1), innerOutline.x * innerOutline.y * 0.3);
    returnFinalColour(startValue);
}
