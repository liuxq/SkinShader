// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

uniform samplerCUBE _SkyCubeIBL;
#ifdef 	MARMO_SKY_BLEND
	uniform samplerCUBE _SkyCubeIBL1;
#endif

uniform fixed4 		_Color;
uniform fixed4 		_ShadowColor;
uniform float 		_ShadowInt;
uniform sampler2D	_MainTex;

struct Input {
	float2 uv_MainTex;
	float3 skyP;
	float3 skyE;
	#ifdef MARMO_SKY_BLEND
		float3 skyP1;
		float3 skyE1;
	#endif
};

inline fixed4 LightingMatte (SurfaceOutput s, fixed3 lightDir, fixed atten) {
    fixed4 c;
    c.rgb = atten*s.Albedo;
    c.a = 1.0-atten;
    return c;
}

//deferred lighting
inline half4 LightingMatte_PrePass( SurfaceOutput s, half4 light ) {
	half4 frag;
	half intensity = saturate(2.0*max(light.r,max(light.g, light.b)));
	frag.rgb = s.Albedo * intensity;
	frag.a = 0.0;
	return frag;
}

void MatteVert(inout appdata_full v, out Input o) {
	UNITY_INITIALIZE_OUTPUT(Input,o);
	
	float3 P = mulPoint3(unity_ObjectToWorld, v.vertex.xyz);
	float3 E = P-_WorldSpaceCameraPos;
	
	o.skyP = mulPoint3(_InvSkyMatrix, P);
	o.skyE = mulVec3(_InvSkyMatrix, E);
	#ifdef MARMO_SKY_BLEND
		o.skyP1 = mulPoint3(_InvSkyMatrix1, P);
		o.skyE1 = mulVec3(_InvSkyMatrix1, E);
	#endif
	//o.skyN = mulVec3(_InvSkyMatrix, mulVec3(_Object2World,v.normal));
}

void MatteSurf (Input IN, inout SurfaceOutput o) {
	half4 exposureIBL = _ExposureIBL;
	
	float4 matte = tex2D(_MainTex, IN.uv_MainTex) * _Color;
		
	#if defined(MARMO_MATTE_WARP)
		IN.skyP = lerp(normalize(IN.skyE), normalize(IN.skyP), matte.a);
		#ifdef MARMO_SKY_BLEND
			IN.skyP1 = lerp(normalize(IN.skyE1), normalize(IN.skyP1), matte.a);
		#endif
	#endif
	
	half3 sky = fromRGBM(texCUBE(_SkyCubeIBL, IN.skyP)) * matte.rgb;
	#if defined(MARMO_MATTE_FADE)
		half3 distant = fromRGBM(texCUBE(_SkyCubeIBL, IN.skyE));
		sky = lerp(distant, sky, matte.a);
	#endif
	
	#ifdef MARMO_SKY_BLEND
		exposureIBL = lerp(_ExposureIBL1, exposureIBL, _BlendWeightIBL);
		half3 sky1 = fromRGBM(texCUBE(_SkyCubeIBL1, IN.skyP1)) * matte.rgb;
		#if defined(MARMO_MATTE_FADE)
			half3 distant1 = fromRGBM(texCUBE(_SkyCubeIBL1, IN.skyE1));
			sky1 = lerp(distant1, sky1, matte.a);
		#endif
		sky = lerp(sky1, sky, _BlendWeightIBL);
	#endif	
	sky *= exposureIBL.z;
	
	float3 shadow = lerp(float3(1.0,1.0,1.0), _ShadowColor.rgb, _ShadowInt * matte.a);
    o.Emission = shadow*sky;
	o.Albedo = sky - sky*shadow;
	o.Alpha = 1.0;
}