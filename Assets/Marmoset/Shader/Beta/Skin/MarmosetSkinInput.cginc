// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

#ifndef MARMOSET_SKIN_INPUT_CGINC
#define MARMOSET_SKIN_INPUT_CGINC

uniform sampler2D 	_MainTex;
uniform float4		_MainTex_ST;

#if defined(MARMO_OCCLUSION) || defined(MARMO_VERTEX_OCCLUSION)
uniform half		_OccStrength;
#endif

#ifdef MARMO_OCCLUSION
uniform sampler2D	_OccTex;
uniform float4		_OccTex_ST;
#endif

#if defined(MARMO_DIFFUSE_DIRECT) || defined(MARMO_DIFFUSE_IBL)
uniform float4		_Color;
#endif

#if defined(MARMO_SPECULAR_DIRECT) || defined(MARMO_SPECULAR_IBL)
	#ifndef MARMO_DIFFUSE_SPECULAR_COMBINED
	uniform sampler2D	_SpecTex;
	uniform float4		_SpecTex_ST;
	#endif
	//uniform float4	_SpecColor; //defined by unity
	uniform float		_SpecInt;
	uniform float		_Shininess;
	uniform float		_Fresnel;
#endif

#ifdef MARMO_NORMALMAP
uniform sampler2D 	_BumpMap;
uniform float4		_BumpMap_ST;
#endif

#ifdef MARMO_GLOW
uniform sampler2D	_Illum;
uniform float4		_GlowColor;
uniform float		_GlowStrength;
uniform float		_EmissionLM;
#endif

uniform float  _NormalSmoothing;

#ifdef MARMO_DETAIL
uniform float  		_DetailWeight;
uniform float		_DetailSmoothing;
uniform sampler2D	_DetailMap;
uniform float4		_DetailMap_ST;
#endif

uniform float	_Subdermis;
uniform float4	_SubdermisColor;
uniform float	_ConserveEnergy;

#ifdef MARMO_SUBDERMIS_MAP
uniform sampler2D _SubdermisTex;
uniform float4 	  _SubdermisTex_ST;
#endif

#ifdef MARMO_SPECULAR_ANISO
uniform float _Aniso;
uniform float _AnisoDir;
#endif

uniform float _Translucency;
uniform float _TranslucencySky;
uniform float4 _TranslucencyColor;
#ifdef MARMO_TRANSLUCENCY_MAP
uniform sampler2D _TranslucencyMap;
uniform float4	  _TranslucencyMap_ST;
#endif

uniform float   _Fuzz;	
uniform float4	_FuzzColor;
uniform float 	_FuzzScatter;
uniform float 	_FuzzOcc;
struct Input {
	float2 texcoord;

	#ifdef MARMO_OCCLUSION
		float2 texcoord1;
	#endif
	
	float3 worldNormal; //internal, required for the WorldNormalVector macro
	
	#if defined(MARMO_SPECULAR_DIRECT) || defined(MARMO_SPECULAR_IBL) || defined(MARMO_SKIN_IBL) || defined(MARMO_SKIN_DIRECT)
		float3 viewDir;
	#endif
	#ifdef MARMO_SPECULAR_IBL
		float3 worldRefl; //internal, required for the WorldReflVector macro
	#endif
	#if defined(MARMO_VERTEX_COLOR) || defined(MARMO_VERTEX_OCCLUSION)
		half4 color : COLOR;
	#endif
	INTERNAL_DATA
};

struct MarmosetSkinOutput {
	half3 Albedo;	//diffuse map RGB
	half Alpha;		//diffuse map A
	half3 Normal;	//world-space normal
	half3 Emission;	//contains IBL contribution
	half Specular;	//specular exponent (required by Unity)
	#ifdef MARMO_SPECULAR_DIRECT
		half3 SpecularRGB;	//specular mask
	#endif
	#if defined(MARMO_SKIN_DIRECT) || defined(MARMO_SKIN_IBL)
		half3 Subdermis;
		half3 Translucency;
		half  Fuzz;
	#endif
	#ifdef MARMO_SPECULAR_ANISO
		half3 anisoTangent;
	#endif
};
#endif