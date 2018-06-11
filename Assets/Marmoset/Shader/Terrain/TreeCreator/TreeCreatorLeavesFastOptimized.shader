// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Hidden/Marmoset/Nature/Tree Creator Leaves Fast Optimized" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_TranslucencyColor ("Translucency Color", Color) = (0.73,0.85,0.41,1) // (187,219,106,255)
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.3
	_TranslucencyViewDependency ("View dependency", Range(0,1)) = 0.7
	_ShadowStrength("Shadow Strength", Range(0,1)) = 1.0
	
	_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
	_ShadowTex ("Shadow (RGB)", 2D) = "white" {}

	// These are here only to provide default values
	[HideInInspector] _TreeInstanceColor ("TreeInstanceColor", Vector) = (1,1,1,1)
	[HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
	[HideInInspector] _SquashAmount ("Squash", Float) = 1
}

SubShader { 
	Tags {
		"IgnoreProjector"="True"
		"RenderType" = "TreeLeaf"
	}
	LOD 200

	Pass {
		Tags { "LightMode" = "ForwardBase" }
		Name "ForwardBase"

	CGPROGRAM
		#include "UnityBuiltin3xTreeLibrary.cginc"
		#include "UnityCG.cginc"
		#include "TerrainEngine.cginc"
		#include "../../MarmosetCore.cginc"
		#include "TreeCore.cginc"
		#include "TreeVertexLit.cginc"


		#pragma vertex VertexLeaf
		#pragma fragment FragmentLeaf
		#pragma exclude_renderers flash
		#pragma multi_compile_fwdbase nolightmap
		#pragma multi_compile MARMO_TERRAIN_BLEND_OFF MARMO_TERRAIN_BLEND_ON
		#if MARMO_TERRAIN_BLEND_ON			
			#define MARMO_SKY_BLEND
		#endif
		
		#define MARMO_SKY_ROTATION
		#include "UnityBuiltin3xTreeLibrary.cginc"
		
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;

		uniform fixed _Cutoff;
		uniform sampler2D _ShadowMapTexture;

		struct v2f_leaf {
			float4 pos : SV_POSITION;
			half4 diffuse : TEXCOORD2;
		#if defined(SHADOWS_SCREEN)
			fixed4 mainLight : COLOR0;
		#endif
			float2 uv : TEXCOORD0;
		#if defined(SHADOWS_SCREEN)
			float4 screenPos : TEXCOORD1;
		#endif
		};

		v2f_leaf VertexLeaf (appdata_full v)
		{
			v2f_leaf o;
			TreeVertLeaf(v);
			o.pos = UnityObjectToClipPos(v.vertex);

			fixed ao = v.color.a;
			ao += 0.1; ao = saturate(ao * ao * ao); // emphasize AO

			fixed3 color = v.color.rgb * _Color.rgb * ao;
			
			float3 worldN = mul ((float3x3)unity_ObjectToWorld, SCALED_NORMAL);

			fixed4 mainLight;
			mainLight.rgb = MarmoShadeTranslucentMainLight (v.vertex, worldN) * color;
			mainLight.a = v.color.a;
			o.diffuse.rgb = MarmoShadeTranslucentLights (v.vertex, worldN) * color;
			o.diffuse.a = 1;
		#if defined(SHADOWS_SCREEN)
			o.mainLight = mainLight;
			o.screenPos = ComputeScreenPos (o.pos);
		#else
			o.diffuse *= 0.5;
			o.diffuse += mainLight;
		#endif			
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);			
			float3 skyN = normalize(skyRotate(_SkyMatrix,v.normal.xyz));
			o.diffuse.rgb += SHLookup(skyN) * _ExposureIBL.x * _UniformOcclusion.x;
			
			return o;
		}

		fixed4 FragmentLeaf (v2f_leaf IN) : COLOR
		{
			fixed4 albedo = tex2D(_MainTex, IN.uv);
			fixed alpha = albedo.a;
			clip (alpha - _Cutoff);

		#if defined(SHADOWS_SCREEN)
			half4 light = IN.mainLight;
			half atten = tex2Dproj(_ShadowMapTexture, UNITY_PROJ_COORD(IN.screenPos)).r;
			light.rgb *= lerp(2, 2*atten, _ShadowStrength);
			light.rgb += IN.diffuse.rgb;
		#else
			half4 light = IN.diffuse;
			light.rgb *= 2.0;
		#endif
			light.rgb *= _ExposureIBL.w;
			return fixed4 (albedo.rgb * light, 0.0);
		}

	ENDCG
	}

	// Pass to render object as a shadow caster
	Pass {
		Name "ShadowCaster"
		Tags { "LightMode" = "ShadowCaster" }
		
		ZWrite On ZTest LEqual

	CGPROGRAM
		#pragma vertex vert_surf
		#pragma fragment frag_surf
		#pragma multi_compile_shadowcaster
		#include "HLSLSupport.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"

		#define INTERNAL_DATA
		#define WorldReflectionVector(data,normal) data.worldRefl

		#include "UnityBuiltin3xTreeLibrary.cginc"

		sampler2D _MainTex;

		struct v2f_surf {
			V2F_SHADOW_CASTER;
			float2 hip_pack0 : TEXCOORD1;
		};
		
		float4 _MainTex_ST;
		
		v2f_surf vert_surf (appdata_full v) {
			v2f_surf o;
			TreeVertLeaf (v);
			o.hip_pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
			return o;
		}
		
		fixed _Cutoff;
		
		half4 frag_surf (v2f_surf IN) : SV_Target {
			fixed alpha = tex2D(_MainTex, IN.hip_pack0.xy).a;
			clip (alpha - _Cutoff);
			SHADOW_CASTER_FRAGMENT(IN)
		}
	ENDCG
	}
}
Dependency "BillboardShader" = "Hidden/Marmoset/Nature/Tree Creator Leaves Rendertex"
}
