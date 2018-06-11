// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Marmoset/Nature/Tree Creator Bark Rendertex" {
Properties {
	_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
	_BumpSpecMap ("Normalmap (GA) Spec (R)", 2D) = "bump" {}
	_TranslucencyMap ("Trans (RGB) Gloss(A)", 2D) = "white" {}
	
	// These are here only to provide default values
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
}

//Billboard tree renderer used to display (not capture) billboard textures
SubShader {
	Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		
		#pragma multi_compile MARMO_TERRAIN_BLEND_OFF MARMO_TERRAIN_BLEND_ON
		#if MARMO_TERRAIN_BLEND_ON			
			#define MARMO_SKY_BLEND
		#endif

		//#define MARMO_SPECULAR_DIRECT
		#define MARMO_SKY_ROTATION

		#include "UnityCG.cginc"
		
		#include "../../MarmosetCore.cginc"
		#include "TreeCore.cginc"
		
		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float3 color : TEXCOORD6;
			float2 params[3]: TEXCOORD2;
		};

		CBUFFER_START(UnityTerrainImposter)
			float3 _TerrainTreeLightDirections[4];
			float4 _TerrainTreeLightColors[4];
		CBUFFER_END

		v2f vert (appdata_full v) {
			v2f o;
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv = v.texcoord.xy;
			float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
			
			for (int j = 0; j < 3; j++)
			{
				float3 lightDir = _TerrainTreeLightDirections[j];
			
				half nl = dot (v.normal, lightDir);
				o.params[j].r = max (0, nl);
				
				half3 h = normalize (lightDir + viewDir);
				float nh = max (0, dot (v.normal, h));
				o.params[j].g = nh;
			}
			
			o.color = v.color.a;
			return o;
		}

		sampler2D _MainTex;
		sampler2D _BumpSpecMap;
		sampler2D _TranslucencyMap;
		fixed4 _SpecColor;

		fixed4 frag (v2f i) : COLOR
		{
			half4 exposureIBL = blendedExposure();
			
			fixed3 albedo = tex2D (_MainTex, i.uv).rgb * i.color;
			
			half gloss = tex2D(_TranslucencyMap, i.uv).a;
			#ifdef MARMO_SPECULAR_DIRECT
				half specular = tex2D (_BumpSpecMap, i.uv).r * 128.0;
			#endif
			half3 light = UNITY_LIGHTMODEL_AMBIENT;
			half3 ibl = blendedSHAmbient();
			ibl = (ibl * exposureIBL.x);
			
			for (int j = 0; j < 3; j++)
			{
				half3 lightColor = _TerrainTreeLightColors[j].rgb;
				
				half nl = i.params[j].r;
				light += lightColor * nl;
				
				#ifdef MARMO_SPECULAR_DIRECT
					float nh = i.params[j].g;
					float spec = pow (nh, specular) * gloss;
					light += lightColor * _SpecColor.rgb * spec;
				#endif 
			}
			fixed4 c;			
			half3 cLinear = saturate((2.0*light + ibl) * albedo * exposureIBL.w);
			//c.rgb = gammaLerp3(cLinear, toGamma3(cLinear));
			c.rgb = cLinear;
			c.a = 1.0;
			return c;
		}
		ENDCG
	}
}

FallBack Off
}
