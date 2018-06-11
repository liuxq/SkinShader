// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable
// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: unity_Scale shader variable was removed; replaced 'unity_Scale.w' with '1.0'

#ifndef MARMOSET_SH_VERTEX_CGINC
#define MARMOSET_SH_VERTEX_CGINC

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"
#include "../../MarmosetCore.cginc"

float _Occlusion, _AO, _BaseLight;
fixed4 _Color;

#ifdef USE_CUSTOM_LIGHT_DIR
CBUFFER_START(UnityTerrainImposter)
	float3 _TerrainTreeLightDirections[4];
	float4 _TerrainTreeLightColors[4];
CBUFFER_END
#endif

CBUFFER_START(UnityPerCamera2)
// float4x4 _CameraToWorld;
CBUFFER_END

float _HalfOverCutoff;

struct v2f {
	float4 pos  : POSITION;
	float4 uv   : TEXCOORD0;
	half4 color : TEXCOORD1;
};

half4 getExposure() {
	#ifdef MARMO_SKY_BLEND
		half4 exposureIBL = lerp(_ExposureIBL1, _ExposureIBL, _BlendWeightIBL);		
	#else
		half4 exposureIBL = _ExposureIBL;
	#endif
	exposureIBL.xy *= _UniformOcclusion.xy;
	return exposureIBL;
}

half3 getDiffuseIBL( float3 worldN ) {
	float3 skyN = skyRotate(_SkyMatrix, worldN);
	skyN = normalize(skyN);
	half3 diffIBL = SHLookup(skyN);
	#ifdef MARMO_SKY_BLEND
		skyN = skyRotate(_SkyMatrix1, worldN);
		skyN = normalize(skyN);
		half3 diffIBL1 = SHLookup1(skyN); 
		diffIBL = lerp(diffIBL1, diffIBL, _BlendWeightIBL);		
	#endif	
	return diffIBL;
}

v2f leaves(appdata_tree v) {
	v2f o;
	
	TerrainAnimateTree(v.vertex, v.color.w);
	
	float3 viewpos = mul(UNITY_MATRIX_MV, v.vertex);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord;
	
	float4 lightDir = 0;
	float4 lightColor = 0;
	lightDir.w = _AO;

	float4 light = UNITY_LIGHTMODEL_AMBIENT;
	float AO = saturate(_AO * v.tangent.w + _BaseLight);	
	
	float3 worldN = v.normal * 2.0 - float3(1.0,1.0,1.0);
	#ifdef MARMO_OBJECT_NORMAL
		worldN = mul((float3x3)unity_ObjectToWorld, worldN * 1.0);
	#endif
	worldN = normalize(worldN);
	
	//direct
	for (int i = 0; i < 4; i++) {
		float atten = 1.0;
		#ifdef USE_CUSTOM_LIGHT_DIR
			lightDir.xyz = _TerrainTreeLightDirections[i];
			lightColor = _TerrainTreeLightColors[i];
		#else
				float3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
				toLight.z *= -1.0;
				lightDir.xyz = mul( (float3x3)unity_CameraToWorld, normalize(toLight) );
				float lengthSq = dot(toLight, toLight);
				atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
				
				lightColor.rgb = unity_LightColor[i].rgb;
		#endif

		lightDir.xyz *= _Occlusion;		
		float occ = saturate(dot(worldN, lightDir) + _BaseLight);
		light += lightColor * (occ * atten);
	}
	//IBL
	
	half4 exposureIBL = getExposure();
	half3 diffIBL = getDiffuseIBL(worldN);
		
	diffIBL *= exposureIBL.x;
	light.rgb *= _Color.rgb;
	o.color.rgb = (diffIBL.rgb + light.rgb) * exposureIBL.w;
	o.color.a = 0.5 * _HalfOverCutoff;
	
	return o; 
}

v2f bark(appdata_tree v) {
	v2f o;
	
	TerrainAnimateTree(v.vertex, v.color.w);
	
	float3 viewpos = mul(UNITY_MATRIX_MV, v.vertex);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord;
	
	float4 lightDir = 0;
	float4 lightColor = 0;
	lightDir.w = _AO;

	float4 light = UNITY_LIGHTMODEL_AMBIENT;

	float AO = saturate(_AO * v.tangent.w + _BaseLight);
	#ifdef MARMO_OBJECT_NORMAL
		float3 worldN = mul((float3x3)unity_ObjectToWorld, v.normal * 1.0);
	#else
		float3 worldN = v.normal;
	#endif
	
	for (int i = 0; i < 4; i++) {
		float atten = 1.0;
		#ifdef USE_CUSTOM_LIGHT_DIR
			lightDir.xyz = _TerrainTreeLightDirections[i];
			lightColor = _TerrainTreeLightColors[i];
		#else
				float3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
				toLight.z *= -1.0;
				lightDir.xyz = mul( (float3x3)unity_CameraToWorld, normalize(toLight) );
				float lengthSq = dot(toLight, toLight);
				atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
				
				lightColor.rgb = unity_LightColor[i].rgb;
		#endif
		

		float diffuse = dot (worldN, lightDir.xyz);
		diffuse = max(0, diffuse);
		diffuse *= AO;
		light += lightColor * (diffuse * atten);
	}

	half4 exposureIBL = getExposure();
	half3 diffIBL = getDiffuseIBL(worldN);
	
	diffIBL *= AO * exposureIBL.x;
	o.color.rgb = ((diffIBL.rgb + light.rgb) * _Color.rgb) * exposureIBL.w;	
	#ifdef WRITE_ALPHA_1
		o.color.a = 1;
	#else
		o.color.a = _Color.a;
	#endif
	
	return o; 
}

#endif
