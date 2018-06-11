// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

Shader "Marmoset/Matte/Matte Fast" {
Properties {
	_SkyCubeIBL ("Custom Skybox", Cube) = "black" {}
}

SubShader {
	Tags { "Queue"="Background" "RenderType"="Background" }
	Cull Off 
	ZWrite On Fog { Mode Off }
	
	Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma glsl
		#pragma target 3.0
		
		#pragma multi_compile MARMO_SKY_BLEND_OFF MARMO_SKY_BLEND_ON
		#if MARMO_SKY_BLEND_ON		
			#define MARMO_SKY_BLEND
		#endif
		
		#define MARMO_SKY_ROTATION
		#define MARMO_HQ
		
		uniform samplerCUBE _SkyCubeIBL;
		uniform samplerCUBE _SkyCubeIBL1;		
		
		#include "UnityCG.cginc"
		#include "../MarmosetCore.cginc"

		struct appdata_t {
			float4 vertex : POSITION;
			float3 texcoord : TEXCOORD0;
		};

		struct v2f {
			float4 vertex : POSITION;
			float3 skyP : TEXCOORD0;
			#ifdef MARMO_SKY_BLEND
				float3 skyP1 : TEXCOORD1;
			#endif
		};

		v2f vert (appdata_t v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			float3 P = mulPoint3(unity_ObjectToWorld, v.vertex.xyz);
			o.skyP = mulPoint3(_InvSkyMatrix, P);
			#ifdef MARMO_SKY_BLEND
				o.skyP1 = mulPoint3(_InvSkyMatrix1, P).xyz;
			#endif
			return o;
		}

		half4 frag (v2f i) : COLOR
		{
			half4 exposureIBL = _ExposureIBL;
			half4 col = texCUBE(_SkyCubeIBL, i.skyP);
			col.rgb = fromRGBM(col);
			
			#ifdef MARMO_SKY_BLEND			
				exposureIBL = lerp(_ExposureIBL1, exposureIBL, _BlendWeightIBL);
				float4 col1 = texCUBE(_SkyCubeIBL1, i.skyP1);
				col1.rgb = fromRGBM(col1);
				col.rgb = lerp(col1.rgb, col.rgb, _BlendWeightIBL);
			#endif
			col.rgb *= exposureIBL.z;
			col.a = 1.0;
			return col;
		}
		ENDCG 
	}
}
Fallback "Diffuse"
}
