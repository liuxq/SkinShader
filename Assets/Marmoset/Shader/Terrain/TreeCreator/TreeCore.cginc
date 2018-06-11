#ifndef MARMO_TREE_CORE_CGINC
#define MARMO_TREE_CORE_CGINC

//#include "../../MarmosetCore.cginc"

half4 blendedExposure() {
	#ifdef MARMO_SKY_BLEND
		half4 exposureIBL = lerp(_ExposureIBL1, _ExposureIBL, _BlendWeightIBL);
	#else
		half4 exposureIBL = _ExposureIBL;		
	#endif	
	exposureIBL.xy *= _UniformOcclusion.xy;
	return exposureIBL;
}

half3 blendedDiffuseIBL(float3 worldN) {
	float3 skyN = normalize(skyRotate(_SkyMatrix, worldN)); 
	float3 diffIBL = SHLookup(skyN);	
	#ifdef MARMO_SKY_BLEND
		skyN = normalize(skyRotate(_SkyMatrix1, worldN));
		float3 diffIBL1 = SHLookup1(skyN);
		diffIBL = lerp(diffIBL1, diffIBL, _BlendWeightIBL);
	#endif
	return diffIBL;	
}

inline half3 SHAmbient()  { return _SH0.xyz; }

inline half3 blendedSHAmbient() {
#ifdef MARMO_SKY_BLEND
	return lerp(_SH01.xyz, _SH0.xyz, _BlendWeightIBL);
#else
	return _SH0.xyz;
#endif
}


#endif