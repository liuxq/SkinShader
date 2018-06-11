Shader "Hidden/Marmoset/Nature/Tree Creator Leaves Optimized" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_TranslucencyColor ("Translucency Color", Color) = (0.73,0.85,0.41,1) // (187,219,106,255)
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.3
		_TranslucencyViewDependency ("View dependency", Range(0,1)) = 0.7
		_ShadowStrength("Shadow Strength", Range(0,1)) = 0.8
		_ShadowOffsetScale ("Shadow Offset Scale", Float) = 1
		
		_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
		_ShadowTex ("Shadow (RGB)", 2D) = "white" {}
		_BumpSpecMap ("Normalmap (GA) Spec (R) Shadow Offset (B)", 2D) = "bump" {}
		_TranslucencyMap ("Trans (B) Gloss(A)", 2D) = "white" {}

		// These are here only to provide default values
		[HideInInspector] _TreeInstanceColor ("TreeInstanceColor", Vector) = (1,1,1,1)
		[HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
		[HideInInspector] _SquashAmount ("Squash", Float) = 1
		
		_SpecInt ("Specular Intensity", Float) = 1.0
		_Fresnel ("Fresnel Falloff", Range(0.0,1.0)) = 1.0
	}
	
	SubShader { 
		Tags {
			"IgnoreProjector"="True"
			"RenderType"="TreeLeaf"
		}
		LOD 200
		
		CGPROGRAM
		#pragma surface OptLeavesSurf LeavesDirect alphatest:_Cutoff vertex:LeavesVert nolightmap noforwardadd exclude_path:prepass
		#pragma target 3.0
		#pragma multi_compile MARMO_TERRAIN_BLEND_OFF MARMO_TERRAIN_BLEND_ON
		#if MARMO_TERRAIN_BLEND_ON
			#define MARMO_SKY_BLEND
		#endif

		#pragma glsl_no_auto_normalization
		#include "Lighting.cginc"

		// no specular, it looks more or less terrible.
		//#define MARMO_SPECULAR_DIRECT
		
		#define MARMO_SKY_ROTATION
		#include "../../MarmosetCore.cginc"
		#include "TreeCore.cginc"
		
		#include "UnityBuiltin3xTreeLibrary.cginc"
		#include "TerrainEngine.cginc"
		#include "TreeLeavesInput.cginc"
		#include "TreeLeaves.cginc"
		
		ENDCG
		
		// Pass to render object as a shadow caster
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			
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

			struct Input {
				float2 uv_MainTex;
			};

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
			float4 frag_surf (v2f_surf IN) : SV_Target {
				half alpha = tex2D(_MainTex, IN.hip_pack0.xy).a;
				clip (alpha - _Cutoff);
				SHADOW_CASTER_FRAGMENT(IN)
			}
			ENDCG
		}
	}
	
	Dependency "BillboardShader" = "Hidden/Marmoset/Nature/Tree Creator Leaves Rendertex"
	Fallback "Hidden/Nature/Tree Creator Leaves Optimized"
}
