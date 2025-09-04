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
    uniform float3 colour;
    uniform float radian;
vulkan( }; )

vulkan_layout( location = 0 )
in block
{
    vec2 uv0;
} inPs;

void main()
{
    float suppliedRadian = M_PI_F * 2 - 0.2;

    float2 delta = inPs.uv0 - float2(0.5, 0.5);
    float dist = length(delta); // use actual distance, easier for outline thickness

    float outer = 0.5;
    float inner = 0.38;
    float outline = 0.02; // outline thickness in UV units

    if(dist <= outer && dist >= inner) {
        float4 targetCol = float4(0, 0, 0, 0.2); // default = outline

        // inside the "fill" part, away from outline
        if(dist >= inner + outline && dist <= outer - outline) {
            targetCol = float4(colour, 1);
        }

        // Angle measured clockwise from top (north)
        float angle = atan2(delta.x, -delta.y);
        if(angle < 0.0) angle += 2.0 * M_PI_F;

        if(angle <= radian) {
            returnFinalColour(targetCol);
        }
    }

    if(dist <= outer && dist >= inner) {
        float4 targetCol = float4(0, 0, 0, 0.2); // default = outline

        // inside the "fill" part, away from outline
        if(dist >= inner + outline && dist <= outer - outline) {
            targetCol = float4(colour, 1);
        }

        // Angle measured clockwise from top (north)
        float angle = atan2(delta.x, -delta.y);
        if(angle < 0.0) angle += 2.0 * M_PI_F;

        if(angle <= radian) {
            returnFinalColour(targetCol);
        }
    }

    returnFinalColour(float4(0, 0, 0, 0));
}
