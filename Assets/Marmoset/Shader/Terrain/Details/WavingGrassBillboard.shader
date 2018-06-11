// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/TerrainEngine/Details/BillboardWavingDoublePass" {
	Properties {
		_WavingTint ("Fade Color", Color) = (.7,.6,.5, 0)
		_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
		_WaveAndDistance ("Wave and distance", Vector) = (12, 3.6, 1, 1)
		_Cutoff ("Cutoff", float) = 0.5
	}
	
	
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "TerrainEngine.cginc"
		#pragma glsl_no_auto_normalization

		struct v2f {
			float4 pos : POSITION;
			fixed4 color : COLOR;
			float4 uv : TEXCOORD0;
		};
		v2f BillboardVert (appdata_full v) {
			v2f o;
			WavingGrassBillboardVert (v);
			o.color = v.color;
			o.color.rgb *= ShadeVertexLights (v.vertex, v.normal);
			o.pos = UnityObjectToClipPos (v.vertex);	
			o.uv = v.texcoord;
			return o;
		}
	ENDCG

	SubShader {
		Tags {
			"Queue" = "Geometry+200"
			"IgnoreProjector"="True"
			"RenderType"="GrassBillboard"
		}
		Cull Off
		LOD 200
		ColorMask RGB

		CGPROGRAM
			#pragma surface MarmosetGrassSurf Lambert vertex:MarmosetGrassVert addshadow
			#pragma exclude_renderers d3d11_9x flash
			#pragma target 3.0
					
			#pragma multi_compile MARMO_TERRAIN_BLEND_OFF MARMO_TERRAIN_BLEND_ON
			#if MARMO_TERRAIN_BLEND_ON			
				#define MARMO_SKY_BLEND
			#endif
			
			#define MARMO_GRASS_BILLBOARD
			#define MARMO_ALPHA_CLIP
			#define MARMO_SKY_ROTATION
			#define MARMO_DIFFUSE_IBL
			#include "../../MarmosetCore.cginc"
			#include "../MarmosetGrass.cginc"
		ENDCG
	}
	
	Fallback Off
}
