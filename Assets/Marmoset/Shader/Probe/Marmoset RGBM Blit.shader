// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Marmoset Skyshop
// Copyright 2014 Marmoset LLC
// http://marmoset.co

Shader "Hidden/Marmoset/RGBM Blit" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
	}

	SubShader {
		Pass {
			Tags { 
				"Queue"="Background"
				"RenderType"="Background"
			}
			Cull Off ZWrite Off Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_nicest
			#pragma glsl
			#pragma target 3.0
			#pragma multi_compile MARMO_RGBM_INPUT_ON MARMO_RGBM_INPUT_OFF
			#pragma multi_compile MARMO_RGBM_OUTPUT_ON MARMO_RGBM_OUTPUT_OFF
					
			sampler2D _MainTex;
			
			#include "UnityCG.cginc"
			#include "../MarmosetCore.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			v2f vert (appdata_t v) {			
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;
				return o;
			}
			
			//Forces gamma-space rendering to still return linear values from sRGB textures.
			//Call on textures that do NOT bypass sRGB sampling.
			half4 forceLinear3(half4 c) {
				c.rgb = lerp(sRGBToLinear3(c.rgb), c.rgb, IS_LINEAR);			
				return c;
			}
									
			half4 frag (v2f i) : COLOR {
				float4 col = tex2D(_MainTex, i.texcoord);
				col = forceLinear3(col);
				
				#if MARMO_RGBM_INPUT_ON					
					col.rgb = fromRGBM(col);					
				#endif
				
				#if MARMO_RGBM_OUTPUT_ON
					col = HDRtoRGBM(col);
					
					//HACK: why is pre-emptive sRGB undoing not required here? What does Graphics.DrawTexture do?
					//col.rgb = lerp(col.rgb, sRGBToLinear3(col.rgb), IS_LINEAR);
				#else
					col.a = 1.0;
				#endif				
				return col;
			}
			ENDCG 
		}
	}
}
