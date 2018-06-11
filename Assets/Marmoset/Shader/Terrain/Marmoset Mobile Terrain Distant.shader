// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

Shader "Hidden/Marmoset/Mobile/Terrain/Distant IBL" {
//This shader is used to render distant, complex terrain with IBL and 
//a base diffuse map in addition to Unity's splat composite.
	Properties {
		_Color   ("Diffuse Color", Color) = (1,1,1,1)
		_MainTex ("Diffuse(RGB) Alpha(A)", 2D) = "white" {}
	}
	
	SubShader {
		Tags {
			"Queue"="Geometry"
			"RenderType"="Opaque"
		}
		
		LOD 200
		//diffuse LOD 200
		//diffuse-spec LOD 250
		//bumped-diffuse, spec 350
		//bumped-spec 400
		
		//mac stuff
		CGPROGRAM
		#pragma glsl
		#pragma target 3.0
		#pragma exclude_renderers d3d11_9x flash
		#pragma surface MarmosetDistantSurf BlinnPhong exclude_path:prepass noforwardadd 
		//approxview nodirlightmap
		//gamma-correct sampling permutations
				
		#pragma multi_compile MARMO_TERRAIN_BLEND_OFF MARMO_TERRAIN_BLEND_ON
		#if MARMO_TERRAIN_BLEND_ON			
			#define MARMO_SKY_BLEND
		#endif
		
		#define MARMO_HQ
		#define MARMO_SKY_ROTATION
		#define MARMO_DIFFUSE_IBL
		#define MARMO_DIFFUSE_BASE
		
		#include "../MarmosetCore.cginc"
		
		uniform sampler2D _MainTex, _BaseTex;
		uniform float4		_Color;
	
		struct Input {
			float2 uv_MainTex;
			float3 worldNormal;
			INTERNAL_DATA
		};

		void MarmosetDistantSurf(Input IN, inout SurfaceOutput OUT) {
			#ifdef MARMO_SKY_BLEND
				half4 exposureIBL = lerp(_ExposureIBL1, _ExposureIBL, _BlendWeightIBL);
			#else
				half4 exposureIBL = _ExposureIBL;
			#endif
			exposureIBL.xy *= _UniformOcclusion.xy;
			
			//DIFFUSE
			half4 diff = tex2D( _MainTex, IN.uv_MainTex );		//Unity's composite of all splats
			diff *= _Color;
			//camera exposure is built into OUT.Albedo
			diff.rgb *= exposureIBL.w;
			OUT.Albedo = diff.rgb;
			OUT.Alpha = 0.0;
			
			//DIFFUSE IBL
			#ifdef MARMO_DIFFUSE_IBL
				float3 N = IN.worldNormal; //N is in world-space
				N = skyRotate(_SkyMatrix,N); //per-fragment matrix multiply, expensive
				half3 diffIBL = SHLookup(N);
				#ifdef MARMO_SKY_BLEND
					N = IN.worldNormal; //N is in world-space
					N = skyRotate(_SkyMatrix1,N); //per-fragment matrix multiply, expensive
					half3 diffIBL1 = SHLookup1(N);
					diffIBL = lerp(diffIBL1, diffIBL, _BlendWeightIBL);
				#endif
				OUT.Emission += diffIBL * diff.rgb * exposureIBL.x;
			#else
				OUT.Emission = half3(0.0,0.0,0.0);
			#endif
		}


		ENDCG
	}
	
	FallBack "Diffuse"
}
