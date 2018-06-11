// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

Shader "Marmoset/Skydome IBL" {
Properties {
	_SkyCubeIBL ("Custom Sky Cube", Cube) = "white" {}
}

SubShader {
	Tags { "Queue"="Background" "RenderType"="Background" }
	//Cull Off ZWrite Off Fog { Mode Off }	
	Cull Off ZWrite On Fog { Mode Off }
	

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
		
		#define MARMO_HQ
		
		//no sky rotation because the dome geometry rotates by itself
		//#define MARMO_SKY_ROTATION
		
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
			float3 texcoord : TEXCOORD0;
		};

		v2f vert (appdata_t v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			//o.texcoord = skyProject(_SkyMatrix, _InvSkyMatrix, _SkyMin, _SkyMax, v.vertex.xyz, v.vertex.xyz);
			o.texcoord = v.vertex.xyz;			
			return o;
		}

		half4 frag (v2f i) : COLOR
		{
			half4 col = texCUBE(_SkyCubeIBL, i.texcoord);			
			col.rgb = fromRGBM(col) * _ExposureIBL.z;
			#ifdef MARMO_SKY_BLEND			
				float4 col1 = texCUBE(_SkyCubeIBL1, i.texcoord);
				col1.rgb = fromRGBM(col1) * _ExposureIBL1.z;
				col.rgb = lerp(col1.rgb, col.rgb, _BlendWeightIBL);
			#endif
			col.a = 1.0;
			return col;
		}
		ENDCG 
	}
}
Fallback Off
}
