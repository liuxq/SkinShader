// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Hidden/TerrainEngine/Details/Vertexlit" {
	Properties {
		_Color   ("Diffuse Color", Color) = (1,1,1,1)
		_MainTex ("Diffuse(RGB) Alpha(A)", 2D) = "white" {  }
		_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
	}
	SubShader {
		Tags {
			"Queue" = "AlphaTest"
			"IgnoreProjector"="True"
			"RenderType"="Opaque"
		}
		LOD 200
		Pass {
			Tags {
				"LightMode" = "Vertex" 
			}
			ZWrite On ZTest LEqual Cull Off
			AlphaTest Greater [_Cutoff]
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma target 3.0
			//gamma-correct sampling permutations
					
			#pragma multi_compile MARMO_TERRAIN_BLEND_OFF MARMO_TERRAIN_BLEND_ON
			#if MARMO_TERRAIN_BLEND_ON			
				#define MARMO_SKY_BLEND
			#endif
					
			#define MARMO_HQ
			#define MARMO_SKY_ROTATION
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "../../MarmosetCore.cginc"
						
			uniform float4 		_MainTex_ST;
			uniform sampler2D	_MainTex;			
			uniform float4		_Color;
			uniform float		_Cutoff;
						
			struct appdata_t {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float3 texcoord : TEXCOORD0;
			};
		
			struct v2f {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0; 
				float3 vlight : TEXCOORD2;
			};
						
			inline float3 lambert(float3 worldP, float3 worldN) {
				float3 worldL = _WorldSpaceLightPos0.xyz - worldP.xyz*_WorldSpaceLightPos0.w;
				float lengthSq = dot(worldL, worldL);
				float atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[0].z);
				worldL = normalize(worldL);
				float diff = dot(worldN, worldL)*0.5 + 0.5;
				diff *= diff;
				return unity_LightColor[0].rgb * (diff * atten);
			}
			
			v2f vert(appdata_t v) {
				v2f o;
				
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
				
				float3 worldP = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldN = normalize( mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL) );
				float3 worldL = normalize(_WorldSpaceLightPos0.xyz - worldP.xyz*_WorldSpaceLightPos0.w);
				
				o.vlight = lambert(worldP, worldN);
				//o.vlight.rgb += ShadeSH9 (float4(worldN,1.0));
				
				#ifdef MARMO_SKY_BLEND
					half4 exposureIBL = lerp(_ExposureIBL1, _ExposureIBL, _BlendWeightIBL);
				#else
					half4 exposureIBL = _ExposureIBL;
				#endif
				exposureIBL.xy *= _UniformOcclusion;
				
				float3 N = normalize(skyRotate(_SkyMatrix, worldN));
				float3 diffIBL = SHLookup(N);
				#ifdef MARMO_SKY_BLEND
					N = normalize(skyRotate(_SkyMatrix1, worldN));
					float3 diffIBL1 = SHLookup1(N);
					diffIBL = lerp(diffIBL1, diffIBL, _BlendWeightIBL);
				#endif
				
				o.vlight.rgb += diffIBL * exposureIBL.x;
				o.vlight.rgb *= exposureIBL.w;
				
				return o;
			}
		
			half4 frag(v2f IN) : COLOR {
				half4 albedo = tex2D(_MainTex, IN.texcoord);
				//HACK: prior to Unity 4.3, detail meshes are not sRGB sampled. Uncomment if rendering in linear mode and grass is too bright.
				//albedo.rgb = toLinearFast3(albedo.rgb);
				albedo *= _Color;
				clip(albedo.a - _Cutoff);
				
				half4 col;
				col.rgb = IN.vlight.rgb * albedo.rgb;
				col.a = albedo.a;
				return col;
			}
			ENDCG 
		}
	}
	Fallback "Transparent/Cutout/VertexLit"
}
