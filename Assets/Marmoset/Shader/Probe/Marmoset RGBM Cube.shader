// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Marmoset Skyshop
// Copyright 2014 Marmoset LLC
// http://marmoset.co

Shader "Hidden/Marmoset/RGBM Cube" {
	Properties {
		_CubeHDR ("Cubemap", Cube) = "white" {}
	}

	SubShader {
		Pass {
			Tags { 
				"Queue"="Background"
				"RenderType"="Background"
			}
			Cull Off ZWrite On Fog { Mode Off }

			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_nicest
			#pragma glsl
			#pragma target 3.0
					
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
						
			samplerCUBE _CubeHDR;
			
			#include "UnityCG.cginc"
			#include "../MarmosetCore.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float3 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : POSITION;
				float3 texcoord : TEXCOORD0;
			};

			v2f vert (appdata_t v) {
			
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.vertex;
				//o.texcoord = v.texcoord;
				return o;
			}
			
			//Forces gamma-space rendering to still return linear values from sRGB textures.
			//Call on textures that do NOT bypass sRGB sampling.
			half4 forceLinear3(half4 c) {
				c.rgb = lerp(sRGBToLinear3(c.rgb), c.rgb, IS_LINEAR);			
				return c;
			}
									
			half4 frag (v2f i) : COLOR {
				float3 dir = mulVec3(_SkyMatrix, i.texcoord);
				float4 col = texCUBE(_CubeHDR, dir);				
				col = forceLinear3(col);
				#if (MARMO_RGBM_INPUT_ON && MARMO_RGBM_OUTPUT_ON) || (MARMO_RGBM_INPUT_OFF && MARMO_RGBM_OUTPUT_OFF)
				//	return col;
				#endif
				
				#if MARMO_RGBM_INPUT_ON
					col.rgb = fromRGBM(col);					
				#endif
				
				#if MARMO_RGBM_OUTPUT_ON
					col = HDRtoRGBM(col);
					//output gets converted to sRGB by gamma correction, premptively undo it
					col.rgb = lerp(col.rgb, sRGBToLinear3(col.rgb), IS_LINEAR);		
				#else
					col.a = 1.0;
				#endif
				return col;
			}
			ENDCG 
		}
	}
}
