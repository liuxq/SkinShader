Shader "Marmoset/Nature/Tree Creator Leaves" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
	
	_SpecInt ("Specular Intensity", Float) = 1.0
	_Fresnel ("Fresnel Falloff", Range(0.0,1.0)) = 1.0
	
	_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_GlossMap ("Gloss (A)", 2D) = "black" {}
	_TranslucencyMap ("Translucency (A)", 2D) = "white" {}
	_ShadowOffset ("Shadow Offset (A)", 2D) = "black" {}
	
	// These are here only to provide default values
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.3
	[HideInInspector] _TreeInstanceColor ("TreeInstanceColor", Vector) = (1,1,1,1)
	[HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
	[HideInInspector] _SquashAmount ("Squash", Float) = 1
}

SubShader { 
	Tags { "IgnoreProjector"="True" "RenderType"="TreeLeaf" }
	LOD 200
		
	CGPROGRAM
	#pragma surface LeavesSurf LeavesDirect alphatest:_Cutoff vertex:LeavesVert addshadow nolightmap
	#pragma exclude_renderers d3d11_9x flash
	#pragma target 3.0
			
	#pragma multi_compile MARMO_BOX_PROJECTION_OFF MARMO_BOX_PROJECTION_ON
		#if MARMO_BOX_PROJECTION_ON	
			#define MARMO_BOX_PROJECTION
		#endif
		
		#pragma multi_compile MARMO_SKY_BLEND_OFF MARMO_SKY_BLEND_ON
	#if MARMO_SKY_BLEND_ON
		#define MARMO_SKY_BLEND
	#endif

	#pragma glsl_no_auto_normalization

	#define MARMO_SKY_ROTATION
	// no specular, it looks more or less terrible.
	//#define MARMO_SPECULAR_DIRECT

	#include "../../MarmosetCore.cginc"
	#include "TreeCore.cginc"
		
	#include "UnityBuiltin3xTreeLibrary.cginc"
	#include "TerrainEngine.cginc"
	#include "TreeLeavesInput.cginc"
	#include "TreeLeaves.cginc"

	ENDCG
}

Dependency "OptimizedShader" = "Hidden/Marmoset/Nature/Tree Creator Leaves Optimized"
FallBack "Diffuse"
}
