// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

Shader "Marmoset/Projection Box" {
Properties {
	_Color   ("Diffuse Color", Color) = (1,1,1,1)
	_SkyCubeIBL ("Custom Sky Cube", Cube) = "white" {}
}

SubShader {
	Blend SrcAlpha One
	ZTest Always ZWrite Off
	Tags {
		"Queue"="Transparent"
		"RenderType"="Transparent"
		"IgnoreProjector"="True"
	}
	LOD 400

	Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma glsl
		#pragma target 3.0
				
		#pragma multi_compile MARMO_BOX_PROJECTION_OFF MARMO_BOX_PROJECTION_ON
		#if MARMO_BOX_PROJECTION_ON	
			#define MARMO_BOX_PROJECTION
		#endif
		
		#define MARMO_HQ
		
		uniform samplerCUBE _SkyCubeIBL;
		uniform float4		_Color;
		
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
			o.texcoord = v.vertex.xyz;
			return o;
		}

		half4 frag (v2f i) : COLOR
		{
			float3 pos = i.texcoord;
			float3 dir = skyProject(_SkyMatrix, _InvSkyMatrix, _SkyMin, _SkyMax, pos, pos);
			half4 col = texCUBE(_SkyCubeIBL, dir);
			col.rgb = fromRGBM(col) * _ExposureIBL.z;
			col.a = 1.0;
			col *= _Color;
			return col;
		}
		ENDCG 
	}
}

Fallback Off

}
