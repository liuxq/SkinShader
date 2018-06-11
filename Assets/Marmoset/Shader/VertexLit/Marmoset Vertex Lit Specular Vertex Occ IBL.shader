Shader "Marmoset/Vertex Lit/Specular Vertex Occ IBL" {
	Properties {
		_Color   ("Diffuse Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (1,1,1,1)
		_SpecInt ("Specular Intensity", Float) = 1.0
		_Shininess ("Specular Sharpness", Range(2.0,8.0)) = 4.0
		_Fresnel ("Fresnel Falloff", Range(0,1)) = 0.0
		_OccStrength ("Occlusion Strength", Range(0,1)) = 1.0
		_MainTex ("Diffuse(RGB) Spec. Mask(A)", 2D) = "white" {}
		
		
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Pass {
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			//Tags { "LightMode"="Vertex" }	works with lightmaps but no SH vars are defined yet
			//Tags { "LightMode"="ForwardBase" } SH but no lightmaps
			#pragma glsl
			#pragma target 3.0
			#pragma vertex MarmosetVert
			#pragma fragment MarmosetFrag
			#pragma exclude_renderers flash
			#pragma fragmentoption ARB_precision_hint_fastest
			//gamma-correct sampling permutations
					
			//#pragma multi_compile MARMO_BOX_PROJECTION_OFF MARMO_BOX_PROJECTION_ON
			//#if MARMO_BOX_PROJECTION_ON	
			//	#define MARMO_BOX_PROJECTION
			//#endif
			
			#pragma multi_compile MARMO_SKY_BLEND_OFF MARMO_SKY_BLEND_ON
		
			#if MARMO_SKY_BLEND_ON
				#define MARMO_SKY_BLEND
			#endif
								
			#define MARMO_HQ
			#define MARMO_DIFFUSE_IBL
			#define MARMO_SPECULAR_IBL
			#define MARMO_SKY_ROTATION
			#define MARMO_MIP_GLOSS
			#define MARMO_VERTEX_SH
			#define MARMO_VERTEX_DIRECT
			#define MARMO_FORWARDBASE
			//#define MARMO_OCCLUSION
			//#define MARMO_VERTEX_COLOR
			#define MARMO_VERTEX_OCCLUSION
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "../MarmosetCore.cginc"
			#include "../MarmosetVertex.cginc"
			
			ENDCG 
		}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Pass {
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			//Tags { "LightMode"="Vertex" }	works with lightmaps but no SH vars are defined yet
			//Tags { "LightMode"="ForwardBase" } SH but no lightmaps
			#pragma glsl
			#pragma vertex MarmosetVert
			#pragma fragment MarmosetFrag
			#pragma exclude_renderers flash
			#pragma fragmentoption ARB_precision_hint_fastest
			//gamma-correct sampling permutations
					
			//#pragma multi_compile MARMO_BOX_PROJECTION_OFF MARMO_BOX_PROJECTION_ON
			//#if MARMO_BOX_PROJECTION_ON	
			//	#define MARMO_BOX_PROJECTION
			//#endif
			
			#pragma multi_compile MARMO_SKY_BLEND_OFF MARMO_SKY_BLEND_ON
		
			#if MARMO_SKY_BLEND_ON
				#define MARMO_SKY_BLEND
			#endif
					
			#define MARMO_HQ
			#define MARMO_DIFFUSE_IBL
			#define MARMO_SPECULAR_IBL
			#define MARMO_SKY_ROTATION
			//#define MARMO_MIP_GLOSS
			#define MARMO_VERTEX_SH
			#define MARMO_VERTEX_DIRECT
			#define MARMO_FORWARDBASE
			//#define MARMO_OCCLUSION
			//#define MARMO_VERTEX_COLOR
			#define MARMO_VERTEX_OCCLUSION
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "../MarmosetCore.cginc"
			#include "../MarmosetVertex.cginc"
			
			ENDCG 
		}
	}
	Fallback "Marmoset/Vertex Lit/Specular IBL"
}
