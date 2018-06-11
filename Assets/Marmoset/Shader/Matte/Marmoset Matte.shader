Shader "Marmoset/Matte/Matte" {
	Properties {
		_Color   ("Matte Color", Color) = (1,1,1,1)
		_ShadowColor ("Shadow Color", Color) = (1,1,1,1)
	    _ShadowInt ("Shadow Intensity", Range(0,1)) = 1.0
		_MainTex ("Matte(RGB) Mask(A)", 2D) = "white" {}
		_SkyCubeIBL ("Custom Skybox", Cube) = "black" {}
	}

	SubShader {
	    Tags {
			"Queue"="Geometry"
			"RenderType"="Opaque"
		}
		LOD 200
		
		CGPROGRAM
		#pragma glsl
		#pragma target 3.0
		#pragma surface MatteSurf Matte vertex:MatteVert nolightmap nometa
		#pragma multi_compile MARMO_SKY_BLEND_OFF MARMO_SKY_BLEND_ON
		#if MARMO_SKY_BLEND_ON		
			#define MARMO_SKY_BLEND
		#endif
		
		//#define MARMO_MATTE_WARP
		#define MARMO_MATTE_FADE
		
		#include "../MarmosetCore.cginc"
		#include "MarmosetMatte.cginc"
		
		ENDCG
	}
	Fallback "Diffuse"
}