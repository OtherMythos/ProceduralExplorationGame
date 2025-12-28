#include <metal_stdlib>
using namespace metal;

//----------------------------------------------------------

#define sizeForTexture( x ) float2(x.get_width(), x.get_height())
#define OGRE_Sample( tex, sampler, uv ) tex.sample( sampler, uv )

#define readUniform( x ) p.x

#define returnFinalColour( x ) return x
//----------------------------------------------------------

struct PS_INPUT
{
	float2 uv0;
};

struct Params
{
	float3 iResolution;
	float iTime;
};

//Hash function
float hash(float2 p){
	p = fract(p * float2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

//Value noise
float noise(float2 p){
	float2 i = floor(p);
	float2 f = fract(p);

	float a = hash(i);
	float b = hash(i + float2(1.0, 0.0));
	float c = hash(i + float2(0.0, 1.0));
	float d = hash(i + float2(1.0, 1.0));

	float2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		   (c - a) * u.y * (1.0 - u.x) +
		   (d - b) * u.x * u.y;
}

//FBM
float fbm(float2 p){
	float v = 0.0;
	float a = 0.5;

	for(int i = 0; i < 5; i++){
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

fragment float4 main_metal
(
	PS_INPUT inPs [[stage_in]],
	constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{
	float2 uv = inPs.uv0 - 0.5;
	uv.x *= p.iResolution.x / p.iResolution.y;

	float time = p.iTime * 0.15;

	float2 flow = float2(
		fbm(uv * 3.0 + time),
		fbm(uv * 3.0 - time)
	);

	float pattern = fbm(uv * 4.0 + flow * 2.0);

	float wave = sin((uv.x + uv.y + pattern) * 6.0 + time * 2.0);
	pattern += wave * 0.05;

	//float3 baseColor = float3(0.04, 0.06, 0.09);
	float3 baseColor = float3(0.02, 0.03, 0.045);
	float3 accent    = float3(0.10, 0.14, 0.20);
	//float3 accent    = baseColor;

	float3 color = mix(baseColor, accent, pattern);

	float vignette = smoothstep(0.8, 0.2, length(uv));
	color *= vignette;

	returnFinalColour(float4(color, 1.0));
}
