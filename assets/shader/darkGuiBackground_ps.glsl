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
#define returnFinalColour( x ) fragColour = ( x )

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

vulkan( layout( ogre_P0 ) uniform params { )
	uniform float3 iResolution;
	uniform float iTime;
vulkan( }; )

//Hash function
float hash(vec2 p){
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

//Value noise
float noise(vec2 p){
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		   (c - a) * u.y * (1.0 - u.x) +
		   (d - b) * u.x * u.y;
}

//FBM
float fbm(vec2 p){
	float v = 0.0;
	float a = 0.5;

	for(int i = 0; i < 5; i++){
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void main()
{
	vec2 uv = inPs.uv0 - 0.5;
	uv.x *= iResolution.x / iResolution.y;

	float time = iTime * 0.15;

	vec2 flow = vec2(
		fbm(uv * 3.0 + time),
		fbm(uv * 3.0 - time)
	);

	float pattern = fbm(uv * 4.0 + flow * 2.0);

	float wave = sin((uv.x + uv.y + pattern) * 6.0 + time * 2.0);
	pattern += wave * 0.05;

	vec3 baseColor = vec3(0.04, 0.06, 0.09);
	vec3 accent    = vec3(0.10, 0.14, 0.20);

	vec3 color = mix(baseColor, accent, pattern);

	float vignette = smoothstep(0.8, 0.2, length(uv));
	color *= vignette;

	returnFinalColour(vec4(color, 1.0));
}
