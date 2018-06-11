// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: unity_Scale shader variable was removed; replaced 'unity_Scale.w' with '1.0'

// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

#ifndef MARMOSET_VERTEX_CGINC
#define MARMOSET_VERTEX_CGINC

uniform float4 		_MainTex_ST;
uniform sampler2D	_MainTex;

#if defined(MARMO_OCCLUSION) || defined(MARMO_VERTEX_OCCLUSION)
uniform float		_OccStrength;
#endif

#ifdef MARMO_OCCLUSION
uniform float4 		_OccTex_ST;
uniform sampler2D	_OccTex;
#endif

uniform float4		_Color;
uniform float		_SpecInt;
uniform float		_Shininess;			
uniform float		_Fresnel;
			
struct appdata_t {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float3 texcoord : TEXCOORD0;
	float3 texcoord1 : TEXCOORD1;
	float4 color : COLOR;
};

struct v2f {
	float4 vertex : POSITION;
	half4 texcoord : TEXCOORD0;
	half4 lighting : TEXCOORD3;
	#ifdef MARMO_SPECULAR_IBL
		half3 skyRefl : TEXCOORD4;
		#ifdef MARMO_SKY_BLEND
			half3 skyRefl1 : TEXCOORD5;
		#endif
	#endif
	#if defined(MARMO_VERTEX_COLOR) || defined(MARMO_VERTEX_OCCLUSION)
		half4 color : COLOR;
	#endif
};

inline float3 softLambert(float4 lightP, float3 P, float3 N) {
	float3 L = lightP.xyz - P*lightP.w;
	float lengthSq = dot(L, L);
	float atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[0].z);
	L = normalize(L);
	float diff = dot(N, L)*0.5 + 0.5;
	diff *= diff * diff;
	diff *= atten;
	return diff.xxx;
}

v2f MarmosetVert(appdata_t v) {
	#ifdef MARMO_SKY_BLEND
		half4 exposureIBL = lerp(_ExposureIBL1, _ExposureIBL, _BlendWeightIBL);
	#else
		half4 exposureIBL = _ExposureIBL;
	#endif
	exposureIBL.xy *= _UniformOcclusion;
	
	v2f o;				
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.texcoord.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
	#ifdef MARMO_OCCLUSION
		o.texcoord.zw = TRANSFORM_TEX(v.texcoord1,_OccTex);
	#else
		o.texcoord.zw = half2(0.0,0.0);
	#endif
	
	float3 worldP = mul(unity_ObjectToWorld, v.vertex).xyz;
	float3 worldN = mul((float3x3)unity_ObjectToWorld, v.normal * 1.0);
	worldN = normalize(worldN);
	
	float3 skyN = skyRotate(_SkyMatrix, worldN);
	#ifdef MARMO_SKY_BLEND
		float3 skyN1 = skyRotate(_SkyMatrix1, worldN);
	#endif
		
	o.lighting = float4(0.0,0.0,0.0,1.0);	
	o.lighting.rgb += UNITY_LIGHTMODEL_AMBIENT.xyz;
	#ifdef MARMO_SPECULAR_IBL
		float3 worldE = WorldSpaceViewDir( v.vertex );
		float3 worldR = reflect( -worldE, worldN );
		
		o.skyRefl = skyRotate(_SkyMatrix, worldR);
		#ifdef MARMO_SKY_BLEND			
			o.skyRefl1 = skyRotate(_SkyMatrix1, worldR);
		#endif
		o.lighting.a = fastFresnel(normalize(worldN), normalize(worldE), _SpecInt, _Fresnel);
	#endif
	
	#ifdef MARMO_VERTEX_DIRECT		
		#ifdef MARMO_FORWARDBASE
			o.lighting.rgb += softLambert(_WorldSpaceLightPos0, worldP, worldN) * _LightColor0.rgb;
		#else
			//Yep. It's different.
			o.lighting.rgb += softLambert(_WorldSpaceLightPos0, worldP, worldN) * unity_LightColor[0].rgb;
		#endif
	#endif
	o.lighting.rgb *= 2.0; //2x to match Unity
	#ifdef MARMO_VERTEX_SH
		o.lighting.rgb += SHLookupUnity(worldN);
	#endif
	
	//spherical harmonics
	float3 diffuseIBL = SHLookup(skyN);
	#ifdef MARMO_SKY_BLEND
		float3 diffuseIBL1 = SHLookup1(skyN1);
		diffuseIBL = lerp(diffuseIBL1, diffuseIBL, _BlendWeightIBL);
	#endif
	o.lighting.rgb += diffuseIBL * exposureIBL.x;
	
	#ifdef MARMO_VERTEX_COLOR
		o.color = v.color;
	#endif
	
	#ifdef MARMO_VERTEX_OCCLUSION
		o.color = lerp(half4(1.0,1.0,1.0,1.0), v.color, _OccStrength);
		#ifdef SHADER_API_D3D11
			//HACK: dx11 seems to swap the red and blue components, combine them to hack-fix AO anyway
			o.color.r *= o.color.b;
		#endif
	#endif
	return o;
}

half4 MarmosetFrag(v2f IN) : COLOR {
	#ifdef MARMO_SKY_BLEND
		half4 exposureIBL = lerp(_ExposureIBL1, _ExposureIBL, _BlendWeightIBL);
	#else
		half4 exposureIBL = _ExposureIBL;
	#endif
	
	half4 albedo = _Color;
	albedo *= tex2D(_MainTex, IN.texcoord.xy);	
	#ifdef MARMO_VERTEX_COLOR
		albedo.rgb *= IN.color.rgb;
	#endif
	
	exposureIBL.xy *= _UniformOcclusion;
	#if defined(MARMO_OCCLUSION) || defined(MARMO_VERTEX_OCCLUSION)
		half4 occ = half4(1.0,1.0,1.0,1.0);	
		#ifdef MARMO_OCCLUSION
			occ = tex2D(_OccTex, IN.texcoord.zw);
			occ = lerp(half4(1.0,1.0,1.0,1.0), occ, _OccStrength);
		#endif
		#ifdef MARMO_VERTEX_OCCLUSION
			occ *= IN.color;
		#endif		
		exposureIBL.xy *= occ.rg;
		IN.lighting.rgb *= 0.5*occ.r + 0.5;
	#endif
	
	half3 ibl = half3(0.0,0.0,0.0);	
	#ifdef MARMO_SPECULAR_IBL			
		#ifdef MARMO_MIP_GLOSS
			half3 spec = glossCubeLookup(_SpecCubeIBL, IN.skyRefl, exp2(7 - _Shininess) );
		#else
			half3 spec = specCubeLookup(_SpecCubeIBL, IN.skyRefl);
			albedo.a *= 0.125*_Shininess;
		#endif
		
		#ifdef MARMO_SKY_BLEND
			#ifdef MARMO_MIP_GLOSS
				half3 spec1 = glossCubeLookup(_SpecCubeIBL1, IN.skyRefl1, exp2(7 - _Shininess) );
			#else
				half3 spec1 = specCubeLookup(_SpecCubeIBL1, IN.skyRefl1);
			#endif
			spec = lerp(spec1, spec, _BlendWeightIBL);
		#endif
		
		albedo.a *= albedo.a;
		ibl += (_SpecColor.rgb * spec) * (albedo.a * exposureIBL.y * IN.lighting.a);
	#endif
		
	half4 col;
	col.rgb = ibl + albedo.rgb * IN.lighting;
	col.rgb *= _ExposureIBL.w;
	col.a = albedo.a;
	
	return col;
}

#endif