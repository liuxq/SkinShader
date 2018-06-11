// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

Shader "Marmoset/Beta/Layered/Vertex 4-Layer IBL" {
	Properties {
		_SpecColor ("Specular Color", Color) = (1,1,1,1)
		_SpecInt ("Specular Intensity", Float) = 1.0
		_Shininess ("Specular Sharpness", Range(2.0,8.0)) = 4.0
		
		_FuzzColor ("Fuzz Color", Color) = (1,1,1,1)
		_Fuzz		("Fuzz Strength", Float) = 0.0
		_FuzzScatter ("Fuzz Scatter", Range(0.0,1.0)) = 1.0
		
		///
		_Color   ("Diffuse Color", Color) = (1,1,1,1)
		_MainTex ("Diffuse(RGB) Alpha(A)", 2D) = "white" {}
		
		_Fresnel ("Specular Fresnel", Range(0.0,1.0)) = 0.0
		_SpecTex ("Specular(RGB) Gloss(A)", 2D) = "white" {}
		
		_BumpMap  ("Normal Map", 2D) 	= "bump" {}
				
		///
		_Color1   ("Diffuse Color 2", Color) = (1,1,1,1)
		_MainTex1 ("Diffuse Layer 2", 2D) = "white" {}
		
		_Fresnel1 ("Specular Fresnel 2", Range(0.0,1.0)) = 0.0
		_SpecTex1 ("Specular Layer 2", 2D) = "white" {}
		
		_BumpMap1 ("Normal Layer 2", 2D) = "bump" {}
		
		///
		_Color2   ("Diffuse Color 3", Color) = (1,1,1,1)
		_MainTex2 ("Diffuse Layer 3", 2D) = "white" {}
		
		_Fresnel2 ("Specular Fresnel 3", Range(0.0,1.0)) = 0.0
		_SpecTex2 ("Specular Layer 3", 2D) = "white" {}
		
		_BumpMap2 ("Normal Layer 3", 2D) = "bump" {}
		
		///
		_Color3   ("Diffuse Color 4", Color) = (1,1,1,1)
		_MainTex3 ("Diffuse Layer 4", 2D) = "white" {}
		
		/*
		_Fresnel3 ("Specular Fresnel 4", Range(0.0,1.0)) = 0.0
		_SpecTex3 ("Specular Layer 4", 2D) = "white" {}
		
		_BumpMap3 ("Normal Layer 4", 2D) = "bump" {}
		*/
	}
	
	SubShader {
		Tags {
			"Queue"="Geometry"
			"RenderType"="Opaque"
		}
		LOD 400
		//diffuse LOD 200
		//diffuse-spec LOD 250
		//bumped-diffuse, spec 350
		//bumped-spec 400
		
		//mac stuff
		CGPROGRAM
		#ifdef SHADER_API_OPENGL
			#pragma glsl
		#endif
				
		#pragma target 3.0
		#pragma exclude_renderers gles gles3 metal d3d11_9x flash
		#pragma surface MarmosetSurf MarmosetDirect vertex:MarmosetVert fullforwardshadows 
		
		#define MARMO_DIFFUSE_FUZZ
		//TODO: not enough interpolators to get worldPos into box projection >_<
		
		//diffuse always on
		#define MARMO_DIFFUSE_ON 1
		
		#define MARMO_LAYER_MASK_VERTEX_COLOR 1
		#define MARMO_LAYER_COUNT_4_LAYER 1
		
		#define MARMO_SPECULAR_ON 1		
		
		#define MARMO_BUMP_ON 1
		
		#define MARMO_DIFFUSE_SPECULAR_COMBINED_ON 0
		
		#pragma multi_compile MARMO_SKY_BLEND_OFF		MARMO_SKY_BLEND_ON
			
		#define MARMO_HQ
		#define MARMO_SKY_ROTATION		
		#define MARMO_CUSTOM_TILING
		
		#if MARMO_LAYER_MASK_VERTEX_COLOR
			#define MARMO_VERTEX_LAYER_MASK
		
		#elif MARMO_LAYER_MASK_TEXTURE_UV0
			#define MARMO_TEXTURE_LAYER_MASK			
			//TEMP: Nice to have. Note that in UV1 mode there's no room for vertex occlusion
			#define MARMO_VERTEX_OCCLUSION
		
		#elif MARMO_LAYER_MASK_TEXTURE_UV1
			#define MARMO_TEXTURE_LAYER_MASK
			#define MARMO_TEXTURE_LAYER_MASK_UV1
		#endif
		
		#if MARMO_LAYER_COUNT_4_LAYER
			#define MARMO_DIFFUSE_4_LAYER			
			//#define MARMO_SPECULAR_4_LAYER
			//#define MARMO_NORMALMAP_4_LAYER
			//last layer is diffuse only, not enough texture units!
			#if MARMO_DIFFUSE_SPECULAR_COMBINED_ON
				#define MARMO_NORMALMAP_4_LAYER
			#else
				#define MARMO_SPECULAR_3_LAYER
				#define MARMO_NORMALMAP_3_LAYER
			#endif
		#elif MARMO_LAYER_COUNT_2_LAYER
			#define MARMO_DIFFUSE_2_LAYER
			#define MARMO_SPECULAR_2_LAYER
			#define MARMO_NORMALMAP_2_LAYER
		#endif
				
		uniform float _Fuzz;
		uniform float _FuzzScatter;
		uniform float4 _FuzzColor;
		
		#include "../../MarmosetUber.cginc"										
		#include "../../MarmosetInput.cginc"
		#include "../../MarmosetCore.cginc"
		#include "../../MarmosetDirect.cginc"
		#include "../../MarmosetSurf.cginc"
		
		ENDCG
	}
	FallBack "Diffuse"
}
