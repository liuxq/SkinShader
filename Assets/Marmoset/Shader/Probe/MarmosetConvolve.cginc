// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef MARMO_CONVOLVE_CGINC
#define	MARMO_CONVOLVE_CGINC

uniform samplerCUBE _CubeHDR;
uniform float		_SpecularScale;
uniform float		_SpecularExp;
uniform float		_ImportantLog;

//{ r1, r2, cos( 2*pi*r2 ), sin( 2*pi*r2 ) }
uniform float4
 _PhongRands0,    _PhongRands1,    _PhongRands2,    _PhongRands3,   
 _PhongRands4,    _PhongRands5,    _PhongRands6,    _PhongRands7,   
 _PhongRands8,    _PhongRands9,    _PhongRands10,   _PhongRands11,  
 _PhongRands12,   _PhongRands13,   _PhongRands14,   _PhongRands15,  
 _PhongRands16,   _PhongRands17,   _PhongRands18,   _PhongRands19,  
 _PhongRands20,   _PhongRands21,   _PhongRands22,   _PhongRands23,  
 _PhongRands24,   _PhongRands25,   _PhongRands26,   _PhongRands27,  
 _PhongRands28,   _PhongRands29,   _PhongRands30,   _PhongRands31;
#if SPECULAR_IMPORTANCE_SAMPLES>32
uniform float4
 _PhongRands32,   _PhongRands33,   _PhongRands34,   _PhongRands35,  
 _PhongRands36,   _PhongRands37,   _PhongRands38,   _PhongRands39,  
 _PhongRands40,   _PhongRands41,   _PhongRands42,   _PhongRands43,  
 _PhongRands44,   _PhongRands45,   _PhongRands46,   _PhongRands47,  
 _PhongRands48,   _PhongRands49,   _PhongRands50,   _PhongRands51,  
 _PhongRands52,   _PhongRands53,   _PhongRands54,   _PhongRands55,  
 _PhongRands56,   _PhongRands57,   _PhongRands58,   _PhongRands59,  
 _PhongRands60,   _PhongRands61,   _PhongRands62,   _PhongRands63;
#endif
#if SPECULAR_IMPORTANCE_SAMPLES>64
uniform float4
 _PhongRands64,   _PhongRands65,   _PhongRands66,   _PhongRands67,  
 _PhongRands68,   _PhongRands69,   _PhongRands70,   _PhongRands71,  
 _PhongRands72,   _PhongRands73,   _PhongRands74,   _PhongRands75,  
 _PhongRands76,   _PhongRands77,   _PhongRands78,   _PhongRands79,  
 _PhongRands80,   _PhongRands81,   _PhongRands82,   _PhongRands83,  
 _PhongRands84,   _PhongRands85,   _PhongRands86,   _PhongRands87,  
 _PhongRands88,   _PhongRands89,   _PhongRands90,   _PhongRands91,  
 _PhongRands92,   _PhongRands93,   _PhongRands94,   _PhongRands95,  
 _PhongRands96,   _PhongRands97,   _PhongRands98,   _PhongRands99,  
 _PhongRands100,  _PhongRands101,  _PhongRands102,  _PhongRands103, 
 _PhongRands104,  _PhongRands105,  _PhongRands106,  _PhongRands107, 
 _PhongRands108,  _PhongRands109,  _PhongRands110,  _PhongRands111, 
 _PhongRands112,  _PhongRands113,  _PhongRands114,  _PhongRands115, 
 _PhongRands116,  _PhongRands117,  _PhongRands118,  _PhongRands119, 
 _PhongRands120,  _PhongRands121,  _PhongRands122,  _PhongRands123, 
 _PhongRands124,  _PhongRands125,  _PhongRands126,  _PhongRands127;
#endif

//Forces gamma-space rendering to still return linear values from sRGB textures.
//Call on textures that do NOT bypass sRGB sampling.
half4 forceLinear3(half4 c) {
	c.rgb = lerp(sRGBToLinear3(c.rgb), c.rgb, IS_LINEAR);			
	return c;
}

//returns a random hemisphere vector, with probabilty weighted to a pow() lobe of 'specExp'
float3 phongImportanceSample( float4 r, float specExp )
{
	float cos_theta = pow( r.x, 1.0 / (specExp + 1.0) );
	float sin_theta = sqrt( 1.0 - cos_theta*cos_theta );
	float cos_phi = r.z;
	float sin_phi = r.w;
	return	float3( cos_phi*sin_theta, sin_phi*sin_theta, cos_theta );
}

float3 importanceLookup( float3 r, float3 x, float3 y, float3 z, float4 rand ){
	float3 dir = phongImportanceSample(rand, _SpecularExp);
	float3 localDir = dir.x*x + dir.y*y + dir.z*z;
	
	float pdf = (_SpecularExp + 1.0)/(2.0 * 3.14159) * pow( saturate( dot(localDir,r) ), _SpecularExp );
	float lod = _ImportantLog - 0.5*log2( pdf );
	
	float4 lookup;
	lookup.xyz = localDir;//reflect( -s.vertexEye, localDir );
	lookup.w = lod;
	float4 result = texCUBElod(_CubeHDR, lookup);
	
	//importance sampling always happens in linear space
	#if MARMO_RGBM_INPUT_ON
		result = forceLinear3(result);
		result.rgb *= pow(result.a*6.0, 2.2);
	#endif
	return (1.0/float(SPECULAR_IMPORTANCE_SAMPLES)) * result.rgb;
}

struct appdata_t {
	float4 vertex : POSITION;
	float3 texcoord : TEXCOORD0;
};

struct v2f {
	float4 vertex : POSITION;
	float3 texcoord : TEXCOORD0;
};

v2f convolveVert (appdata_t v) {
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.texcoord = v.texcoord;
	return o;
}

half4 convolveFrag (v2f i) : COLOR {
	float3 n = normalize(mulVec3(_SkyMatrix, normalize(i.texcoord)));
	
	//sample the reflection map repeatedly, with an importance-based sample distribution
	float3 bx = normalize(cross(n,float3(0.0, 1.0, saturate(n.y*10000.0 - 9999.0))));
	float3 by = normalize(cross(bx,n));
	float3 bz = normalize(n);
	float3 spec = float3(0.0,0.0,0.0);
	
	spec =
	importanceLookup(n, bx, by, bz, _PhongRands0)   +  importanceLookup(n, bx, by, bz, _PhongRands1)   +  importanceLookup(n, bx, by, bz, _PhongRands2)   +  importanceLookup(n, bx, by, bz, _PhongRands3)   + 
	importanceLookup(n, bx, by, bz, _PhongRands4)   +  importanceLookup(n, bx, by, bz, _PhongRands5)   +  importanceLookup(n, bx, by, bz, _PhongRands6)   +  importanceLookup(n, bx, by, bz, _PhongRands7)   + 
	importanceLookup(n, bx, by, bz, _PhongRands8)   +  importanceLookup(n, bx, by, bz, _PhongRands9)   +  importanceLookup(n, bx, by, bz, _PhongRands10)  +  importanceLookup(n, bx, by, bz, _PhongRands11)  + 
	importanceLookup(n, bx, by, bz, _PhongRands12)  +  importanceLookup(n, bx, by, bz, _PhongRands13)  +  importanceLookup(n, bx, by, bz, _PhongRands14)  +  importanceLookup(n, bx, by, bz, _PhongRands15)  + 
	importanceLookup(n, bx, by, bz, _PhongRands16)  +  importanceLookup(n, bx, by, bz, _PhongRands17)  +  importanceLookup(n, bx, by, bz, _PhongRands18)  +  importanceLookup(n, bx, by, bz, _PhongRands19)  + 
	importanceLookup(n, bx, by, bz, _PhongRands20)  +  importanceLookup(n, bx, by, bz, _PhongRands21)  +  importanceLookup(n, bx, by, bz, _PhongRands22)  +  importanceLookup(n, bx, by, bz, _PhongRands23)  + 
	importanceLookup(n, bx, by, bz, _PhongRands24)  +  importanceLookup(n, bx, by, bz, _PhongRands25)  +  importanceLookup(n, bx, by, bz, _PhongRands26)  +  importanceLookup(n, bx, by, bz, _PhongRands27)  + 
	importanceLookup(n, bx, by, bz, _PhongRands28)  +  importanceLookup(n, bx, by, bz, _PhongRands29)  +  importanceLookup(n, bx, by, bz, _PhongRands30)  +  importanceLookup(n, bx, by, bz, _PhongRands31);
	#if SPECULAR_IMPORTANCE_SAMPLES>32
	spec +=
	importanceLookup(n, bx, by, bz, _PhongRands32)  +  importanceLookup(n, bx, by, bz, _PhongRands33)  +  importanceLookup(n, bx, by, bz, _PhongRands34)  +  importanceLookup(n, bx, by, bz, _PhongRands35)  + 
	importanceLookup(n, bx, by, bz, _PhongRands36)  +  importanceLookup(n, bx, by, bz, _PhongRands37)  +  importanceLookup(n, bx, by, bz, _PhongRands38)  +  importanceLookup(n, bx, by, bz, _PhongRands39)  + 
	importanceLookup(n, bx, by, bz, _PhongRands40)  +  importanceLookup(n, bx, by, bz, _PhongRands41)  +  importanceLookup(n, bx, by, bz, _PhongRands42)  +  importanceLookup(n, bx, by, bz, _PhongRands43)  + 
	importanceLookup(n, bx, by, bz, _PhongRands44)  +  importanceLookup(n, bx, by, bz, _PhongRands45)  +  importanceLookup(n, bx, by, bz, _PhongRands46)  +  importanceLookup(n, bx, by, bz, _PhongRands47)  + 
	importanceLookup(n, bx, by, bz, _PhongRands48)  +  importanceLookup(n, bx, by, bz, _PhongRands49)  +  importanceLookup(n, bx, by, bz, _PhongRands50)  +  importanceLookup(n, bx, by, bz, _PhongRands51)  + 
	importanceLookup(n, bx, by, bz, _PhongRands52)  +  importanceLookup(n, bx, by, bz, _PhongRands53)  +  importanceLookup(n, bx, by, bz, _PhongRands54)  +  importanceLookup(n, bx, by, bz, _PhongRands55)  + 
	importanceLookup(n, bx, by, bz, _PhongRands56)  +  importanceLookup(n, bx, by, bz, _PhongRands57)  +  importanceLookup(n, bx, by, bz, _PhongRands58)  +  importanceLookup(n, bx, by, bz, _PhongRands59)  + 
	importanceLookup(n, bx, by, bz, _PhongRands60)  +  importanceLookup(n, bx, by, bz, _PhongRands61)  +  importanceLookup(n, bx, by, bz, _PhongRands62)  +  importanceLookup(n, bx, by, bz, _PhongRands63);
	#endif
	#if SPECULAR_IMPORTANCE_SAMPLES>64
	spec +=
	importanceLookup(n, bx, by, bz, _PhongRands64)  +  importanceLookup(n, bx, by, bz, _PhongRands65)  +  importanceLookup(n, bx, by, bz, _PhongRands66)  +  importanceLookup(n, bx, by, bz, _PhongRands67)  + 
	importanceLookup(n, bx, by, bz, _PhongRands68)  +  importanceLookup(n, bx, by, bz, _PhongRands69)  +  importanceLookup(n, bx, by, bz, _PhongRands70)  +  importanceLookup(n, bx, by, bz, _PhongRands71)  + 
	importanceLookup(n, bx, by, bz, _PhongRands72)  +  importanceLookup(n, bx, by, bz, _PhongRands73)  +  importanceLookup(n, bx, by, bz, _PhongRands74)  +  importanceLookup(n, bx, by, bz, _PhongRands75)  + 
	importanceLookup(n, bx, by, bz, _PhongRands76)  +  importanceLookup(n, bx, by, bz, _PhongRands77)  +  importanceLookup(n, bx, by, bz, _PhongRands78)  +  importanceLookup(n, bx, by, bz, _PhongRands79)  + 
	importanceLookup(n, bx, by, bz, _PhongRands80)  +  importanceLookup(n, bx, by, bz, _PhongRands81)  +  importanceLookup(n, bx, by, bz, _PhongRands82)  +  importanceLookup(n, bx, by, bz, _PhongRands83)  + 
	importanceLookup(n, bx, by, bz, _PhongRands84)  +  importanceLookup(n, bx, by, bz, _PhongRands85)  +  importanceLookup(n, bx, by, bz, _PhongRands86)  +  importanceLookup(n, bx, by, bz, _PhongRands87)  + 
	importanceLookup(n, bx, by, bz, _PhongRands88)  +  importanceLookup(n, bx, by, bz, _PhongRands89)  +  importanceLookup(n, bx, by, bz, _PhongRands90)  +  importanceLookup(n, bx, by, bz, _PhongRands91)  + 
	importanceLookup(n, bx, by, bz, _PhongRands92)  +  importanceLookup(n, bx, by, bz, _PhongRands93)  +  importanceLookup(n, bx, by, bz, _PhongRands94)  +  importanceLookup(n, bx, by, bz, _PhongRands95)  + 
	importanceLookup(n, bx, by, bz, _PhongRands96)  +  importanceLookup(n, bx, by, bz, _PhongRands97)  +  importanceLookup(n, bx, by, bz, _PhongRands98)  +  importanceLookup(n, bx, by, bz, _PhongRands99)  + 
	importanceLookup(n, bx, by, bz, _PhongRands100) +  importanceLookup(n, bx, by, bz, _PhongRands101) +  importanceLookup(n, bx, by, bz, _PhongRands102) +  importanceLookup(n, bx, by, bz, _PhongRands103) + 
	importanceLookup(n, bx, by, bz, _PhongRands104) +  importanceLookup(n, bx, by, bz, _PhongRands105) +  importanceLookup(n, bx, by, bz, _PhongRands106) +  importanceLookup(n, bx, by, bz, _PhongRands107) + 
	importanceLookup(n, bx, by, bz, _PhongRands108) +  importanceLookup(n, bx, by, bz, _PhongRands109) +  importanceLookup(n, bx, by, bz, _PhongRands110) +  importanceLookup(n, bx, by, bz, _PhongRands111) + 
	importanceLookup(n, bx, by, bz, _PhongRands112) +  importanceLookup(n, bx, by, bz, _PhongRands113) +  importanceLookup(n, bx, by, bz, _PhongRands114) +  importanceLookup(n, bx, by, bz, _PhongRands115) + 
	importanceLookup(n, bx, by, bz, _PhongRands116) +  importanceLookup(n, bx, by, bz, _PhongRands117) +  importanceLookup(n, bx, by, bz, _PhongRands118) +  importanceLookup(n, bx, by, bz, _PhongRands119) + 
	importanceLookup(n, bx, by, bz, _PhongRands120) +  importanceLookup(n, bx, by, bz, _PhongRands121) +  importanceLookup(n, bx, by, bz, _PhongRands122) +  importanceLookup(n, bx, by, bz, _PhongRands123) + 
	importanceLookup(n, bx, by, bz, _PhongRands124) +  importanceLookup(n, bx, by, bz, _PhongRands125) +  importanceLookup(n, bx, by, bz, _PhongRands126) +  importanceLookup(n, bx, by, bz, _PhongRands127);
	#endif
	
	float4 result = float4(0.0,0.0,0.0,1.0);
	result.rgb = spec * _SpecularScale;
	
	#if MARMO_RGBM_OUTPUT_ON
		result.rgb = lerp(sRGBToLinear3(result.rgb),result.rgb, IS_LINEAR);
		result = HDRtoRGBM(result);		
		//output gets converted to sRGB by gamma correction, premptively undo it
		result.rgb = lerp(result.rgb, sRGBToLinear3(result.rgb), IS_LINEAR);
		return result;
	#else
		result.a = 1.0;
	#endif	
	return result;
}

#endif
