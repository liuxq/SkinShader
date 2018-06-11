// Marmoset Skyshop
// Copyright 2014 Marmoset LLC
// http://marmoset.co

Shader "Hidden/Marmoset/RGBM Convolve" {
	Properties {
		_CubeHDR ("Cubemap", Cube) = "white" {}
		_SpecularScale ("Specular Scale", Float) = 1.0
		_SpecularExp ("Specular Exponent", Float) = 512
	}

	SubShader {
		Pass {
			Tags { 
				"Queue"="Background"
				"RenderType"="Background"
			}
			Cull Off ZWrite Off Fog { Mode Off }

			
			CGPROGRAM
			#pragma vertex convolveVert
			#pragma fragment convolveFrag
			#pragma fragmentoption ARB_precision_hint_nicest
			#pragma glsl
			#pragma target 3.0
			#pragma only_renderers d3d11 opengl glcore
					
		#pragma multi_compile MARMO_BOX_PROJECTION_OFF MARMO_BOX_PROJECTION_ON
		#if MARMO_BOX_PROJECTION_ON	
			#define MARMO_BOX_PROJECTION
		#endif
		
		#pragma multi_compile MARMO_SKY_BLEND_OFF MARMO_SKY_BLEND_ON
		
		#if MARMO_SKY_BLEND_ON
			#define MARMO_SKY_BLEND
		#endif			
			#pragma multi_compile MARMO_RGBM_INPUT_ON MARMO_RGBM_INPUT_OFF
			#pragma multi_compile MARMO_RGBM_OUTPUT_ON MARMO_RGBM_OUTPUT_OFF
			
			
			#define SPECULAR_IMPORTANCE_SAMPLES 128
			
			#include "UnityCG.cginc"
			#include "../MarmosetCore.cginc"
			#include "MarmosetConvolve.cginc"
			
			ENDCG 
		}
	}
	
	SubShader {
		Pass {
			Tags { 
				"Queue"="Background"
				"RenderType"="Background"
			}
			Cull Off ZWrite Off Fog { Mode Off }
			
			CGPROGRAM
			#pragma vertex convolveVert
			#pragma fragment convolveFrag
			#pragma fragmentoption ARB_precision_hint_nicest
			#pragma glsl
			#pragma target 3.0
			#pragma only_renderers d3d9 d3d11 opengl glcore
					
		#pragma multi_compile MARMO_BOX_PROJECTION_OFF MARMO_BOX_PROJECTION_ON
		#if MARMO_BOX_PROJECTION_ON	
			#define MARMO_BOX_PROJECTION
		#endif
		
		#pragma multi_compile MARMO_SKY_BLEND_OFF MARMO_SKY_BLEND_ON
		
		#if MARMO_SKY_BLEND_ON
			#define MARMO_SKY_BLEND
		#endif			
			#pragma multi_compile MARMO_RGBM_INPUT_ON MARMO_RGBM_INPUT_OFF
			#pragma multi_compile MARMO_RGBM_OUTPUT_ON MARMO_RGBM_OUTPUT_OFF
			
			#define SPECULAR_IMPORTANCE_SAMPLES 64
			
			#include "UnityCG.cginc"
			#include "../MarmosetCore.cginc"
			#include "MarmosetConvolve.cginc"
			
			ENDCG 
		}
	}
	
	SubShader {
		Pass {
			Tags { 
				"Queue"="Background"
				"RenderType"="Background"
			}
			Cull Off ZWrite Off Fog { Mode Off }
			
			CGPROGRAM
			#pragma vertex convolveVert
			#pragma fragment convolveFrag
			#pragma fragmentoption ARB_precision_hint_nicest
			#pragma glsl
			#pragma target 3.0
			#pragma only_renderers d3d9 d3d11 opengl glcore
					
		#pragma multi_compile MARMO_BOX_PROJECTION_OFF MARMO_BOX_PROJECTION_ON
		#if MARMO_BOX_PROJECTION_ON	
			#define MARMO_BOX_PROJECTION
		#endif
		
		#pragma multi_compile MARMO_SKY_BLEND_OFF MARMO_SKY_BLEND_ON
		
		#if MARMO_SKY_BLEND_ON
			#define MARMO_SKY_BLEND
		#endif			
			#pragma multi_compile MARMO_RGBM_INPUT_ON MARMO_RGBM_INPUT_OFF
			#pragma multi_compile MARMO_RGBM_OUTPUT_ON MARMO_RGBM_OUTPUT_OFF
			
			#define SPECULAR_IMPORTANCE_SAMPLES 32
			
			#include "UnityCG.cginc"
			#include "../MarmosetCore.cginc"
			#include "MarmosetConvolve.cginc"
			
			ENDCG 
		}
	}
}

