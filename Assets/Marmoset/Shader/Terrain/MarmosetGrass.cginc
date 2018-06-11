// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: unity_Scale shader variable was removed; replaced 'unity_Scale.w' with '1.0'

// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

uniform sampler2D 	_MainTex;
uniform fixed 		_Cutoff;
//declared by Unity
//uniform float4		_WavingTint;
//uniform float4 		_WaveAndDistance;

struct Input {
	float2 uv_MainTex;
	fixed4 color : COLOR;
	float3 worldNormal;
	half4 diffIBL; //rgb - diffIBL, a - exposure.w
};

void MarmosetGrassVert (inout appdata_full v, out Input o)
{
	UNITY_INITIALIZE_OUTPUT(Input,o);
	//Direct
	#ifdef MARMO_GRASS_BILLBOARD
		TerrainBillboardGrass (v.vertex, v.tangent.xy);
		// wave amount defined by the grass height
		float waveAmount = v.tangent.y;
		v.color = TerrainWaveGrass (v.vertex, waveAmount, v.color);
	#else
		float waveAmount = v.color.a * _WaveAndDistance.z;
		v.color = TerrainWaveGrass (v.vertex, waveAmount, v.color);
	#endif
	
	//IBL	
	#ifdef MARMO_SKY_BLEND
		half4 exposureIBL = lerp(_ExposureIBL1, _ExposureIBL, _BlendWeightIBL);
	#else
		half4 exposureIBL = _ExposureIBL;
	#endif
	exposureIBL.xy *= _UniformOcclusion.xy;

	float3 worldN = mul((float3x3)unity_ObjectToWorld, v.normal * 1.0);
	float3 skyN = skyRotate(_SkyMatrix, worldN);
	skyN = normalize(skyN);
	
	o.diffIBL.rgb = SHLookup(skyN);
	o.diffIBL.a = exposureIBL.w;
	#ifdef MARMO_SKY_BLEND
		skyN = skyRotate(_SkyMatrix1, worldN);
		skyN = normalize(skyN);
		float3 diffIBL1 = SHLookup1(skyN);
		o.diffIBL.rgb = lerp(diffIBL1.rgb, o.diffIBL.rgb, _BlendWeightIBL);
	#endif
	o.diffIBL.rgb *= exposureIBL.x;
}

void MarmosetGrassSurf(Input IN, inout SurfaceOutput o) {
	half4 diff = tex2D(_MainTex, IN.uv_MainTex) * IN.color;	
	o.Alpha = diff.a;
	#ifdef MARMO_ALPHA_CLIP
		clip (o.Alpha - _Cutoff);
	#endif
	
	diff.rgb *= IN.diffIBL.w; //camera exposure is built into OUT.Albedo
	o.Albedo = diff.rgb;
	o.Alpha *= IN.color.a;	
	o.Emission.rgb = IN.diffIBL * diff.rgb;
}

