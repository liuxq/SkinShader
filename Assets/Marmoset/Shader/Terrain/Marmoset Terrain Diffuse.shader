Shader "Marmoset/Terrain/Terrain Diffuse IBL" {
//This is a complex terrain shader featuring base normal and diffuse maps,
//splat normal and diffuse+specular maps, base ambient occlusion, and a 
//host of spec and fresnel controls per layer.
Properties {
	_Color   	("Diffuse Color", Color) = (1,1,1,1)
	
	_DetailWeight ("DetailWeight", Float) = 1.0
	_FadeNear	("Fade Near", Float) = 500.0
	_FadeRange	("Fade Range", Float) = 100.0
	
	_DiffFresnel("Master Diffuse Fresnel", Range(0.0,1.0)) = 0.0
	_Fresnel0	("Diffuse Fresnel 0",Range(0.0,1.0)) = 0.0
	_Fresnel1	("Diffuse Fresnel 1",Range(0.0,1.0)) = 0.0
	_Fresnel2	("Diffuse Fresnel 2",Range(0.0,1.0)) = 0.0
	_Fresnel3	("Diffuse Fresnel 3",Range(0.0,1.0)) = 0.0
	
	_Fresnel4	("Secondary Fresnel 4",Range(0.0,1.0)) = 0.0
	_Fresnel5	("Secondary Fresnel 5",Range(0.0,1.0)) = 0.0
	_Fresnel6	("Secondary Fresnel 6",Range(0.0,1.0)) = 0.0
	_Fresnel7	("Secondary Fresnel 7",Range(0.0,1.0)) = 0.0

	_BaseTex ("Base Diffuse (RGB) Occlusion (A)", 2D) = "white" {}
	_BumpMap ("Base Normalmap (RGB)", 2D) = "bump" {}
	
	// set by terrain engine (and must be exposed this way)
	_Control ("Control (RGBA)", 2D) = "red" {}
	_Splat0 ("Layer 0 (R)", 2D) = "white" {}
	_Splat1 ("Layer 1 (G)", 2D) = "white" {}
	_Splat2 ("Layer 2 (B)", 2D) = "white" {}
	_Splat3 ("Layer 3 (A)", 2D) = "white" {}
	_Normal0 ("Normal 0 (R)", 2D) = "bump" {}
	_Normal1 ("Normal 1 (G)", 2D) = "bump" {}
	_Normal2 ("Normal 2 (B)", 2D) = "bump" {}
	_Normal3 ("Normal 3 (A)", 2D) = "bump" {}	
}
	
SubShader {
	Tags {
		"SplatCount" = "4"
		"Queue" = "Geometry-100"
		"RenderType" = "Opaque"
	}
	CGPROGRAM
	#pragma glsl
	#pragma target 3.0
	//NOTE: BlinnPhong instead of MarmosetDirect is fine here, MarmosetDirect is only needed for RGB specular
	#pragma surface MarmosetTerrainSurf BlinnPhong vertex:MarmosetTerrainVert fullforwardshadows addshadow
	#pragma exclude_renderers d3d11_9x flash
	#pragma multi_compile MARMO_TERRAIN_BLEND_OFF MARMO_TERRAIN_BLEND_ON
	#if MARMO_TERRAIN_BLEND_ON			
		#define MARMO_SKY_BLEND
	#endif


	#define MARMO_HQ
	#define MARMO_DIFFUSE_DIRECT
	//#define MARMO_SPECULAR_DIRECT
	#define MARMO_DIFFUSE_IBL
	//#define MARMO_SPECULAR_IBL
	//#define MARMO_MIP_GLOSS
	#define MARMO_NORMALMAP
	#define MARMO_NORMALMAP_DETAIL
	#define MARMO_SKY_ROTATION
	#define MARMO_DIFFUSE_FRESNEL
	#define MARMO_FIRST_PASS
	#define MARMO_DIFFUSE_BASE

	#include "../MarmosetCore.cginc"
	#include "MarmosetTerrain.cginc"

	ENDCG  
}

Dependency "AddPassShader" = "Hidden/Marmoset/Terrain/Terrain IBL AddPass"
Dependency "BaseMapShader" = "Hidden/Marmoset/Terrain/Distant IBL"

// Fallback to Unity terrain
Fallback "Nature/Terrain/Diffuse"
}
