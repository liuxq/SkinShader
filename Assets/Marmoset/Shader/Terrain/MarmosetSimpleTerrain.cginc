#ifndef MARMOSET_SIMPLE_TERRAIN_CGINC
#define MARMOSET_SIMPLE_TERRAIN_CGINC

uniform sampler2D _Control;
uniform sampler2D _Splat0,_Splat1,_Splat2,_Splat3;
uniform fixed4		_Color;

struct Input {
	float2 uv_Control : TEXCOORD0;
	float2 uv_Splat0 : TEXCOORD1;
	float2 uv_Splat1 : TEXCOORD2;
	float2 uv_Splat2 : TEXCOORD3;
	float2 uv_Splat3 : TEXCOORD4;
	float3 worldNormal;
};

void MarmosetSimpleSurf (Input IN, inout SurfaceOutput OUT) {
	#ifdef MARMO_SKY_BLEND
		half4 exposureIBL = lerp(_ExposureIBL1, _ExposureIBL, _BlendWeightIBL);
	#else
		half4 exposureIBL = _ExposureIBL;	
	#endif
	exposureIBL.xy *= _UniformOcclusion.xy;
		
	half4 splat_control = tex2D (_Control, IN.uv_Control);
	half3 diff;	
	diff  = splat_control.r * tex2D (_Splat0, IN.uv_Splat0).rgb;
	diff += splat_control.g * tex2D (_Splat1, IN.uv_Splat1).rgb;
	diff += splat_control.b * tex2D (_Splat2, IN.uv_Splat2).rgb;
	diff += splat_control.a * tex2D (_Splat3, IN.uv_Splat3).rgb;
	diff *= _Color.rgb;
	diff *= exposureIBL.w; //camera exposure is built into OUT.Albedo	
	OUT.Albedo = diff;
	OUT.Alpha = 0.0;
	
	
	#ifdef MARMO_DIFFUSE_IBL
		float3 N = IN.worldNormal;
		N = skyRotate(_SkyMatrix,N); //per-fragment matrix multiply, expensive
		N = normalize(N);
		half3 diffIBL = SHLookup(N);
		
		#ifdef MARMO_SKY_BLEND
			float3 N1 = IN.worldNormal;
			N1 = skyRotate(_SkyMatrix1, N1); //per-fragment matrix multiply, expensive
			N1 = normalize(N1);
			half3 diffIBL1 = SHLookup1(N1);		
			diffIBL = lerp(diffIBL1, diffIBL, _BlendWeightIBL);
		#endif
		
		OUT.Emission = OUT.Albedo.rgb * diffIBL * exposureIBL.x;
	#else
		OUT.Emission = half3(0.0,0.0,0.0);
	#endif
}

#endif