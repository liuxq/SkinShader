// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

#ifndef MARMOSET_DIRECT_CGINC
#define MARMOSET_DIRECT_CGINC

// Core
inline float3 wrapLighting(float DP, float3 scatter) {
	scatter *= 0.5;
	float3 integral = float3(1.0,1.0,1.0)-scatter;
	float3 light = saturate(DP * integral + scatter);
	float shadow = (DP*0.5+0.5);
	shadow *= shadow;
	return light * integral * shadow;
}

// NOTE: some intricacy in shader compiler on some GLES2.0 platforms (iOS) needs 'viewDir' & 'h'
// to be mediump instead of lowp, otherwise specular highlight becomes too bright.
inline half4 marmosetLighting (MarmosetOutput s, half3 viewDir, half3 lightDir, half3 lightColor) {
	half4 frag = half4(0.0,0.0,0.0,s.Alpha);		
	#if defined(MARMO_DIFFUSE_DIRECT) || defined(MARMO_SPECULAR_DIRECT)
		half3 L = lightDir;
		half3 N = s.Normal;
		#ifdef MARMO_HQ
			L = normalize(L);
		#endif
	#endif
		
	#ifdef MARMO_DIFFUSE_DIRECT
		half dp = saturate(dot(N,L));
		
		#ifdef MARMO_DIFFUSE_SCATTER
			float4 scatter = _Scatter * _ScatterColor;
			half3 diff = wrapLighting(dp, scatter.rgb);
			diff *= 2.0 * s.Albedo.rgb; //*2.0 to match Unity
		#else
			half3 diff = (2.0 * dp) * s.Albedo.rgb; //*2.0 to match Unity
		#endif
		frag.rgb = diff * lightColor;
	#endif
	
	#ifdef MARMO_SPECULAR_DIRECT
		half3 H = normalize(viewDir+L);
		float specRefl = saturate(dot(N,H));
		half3 spec = pow(specRefl, s.Specular*512.0);
		#ifdef MARMO_HQ
			//self-shadowing blinn
			#ifdef MARMO_DIFFUSE_DIRECT
				spec *= saturate(10.0*dp);
			#else
				spec *= saturate(10.0*dot(N,L));
			#endif
		#endif
		spec *= lightColor;
		frag.rgb += (0.5 * spec) * s.SpecularRGB; //*0.5 to match Unity
	#endif
	return frag;
}

//deferred legacy lighting
inline half4 LightingMarmosetDirect_PrePass( MarmosetOutput s, half4 light ) {
	half4 frag = half4(0.0,0.0,0.0,1.0);
	#ifdef MARMO_DIFFUSE_DIRECT
		frag.rgb = s.Albedo * light.rgb;
		frag.a = s.Alpha;
	#endif
	#ifdef MARMO_SPECULAR_DIRECT
		frag.rgb += light.rgb * light.a * s.SpecularRGB * 0.15; //*0.15 to match forward lighting
	#endif
	return frag;
}

//forward lighting
inline half4 LightingMarmosetDirect( MarmosetOutput s, half3 lightDir, half3 viewDir, half atten ) {
	return marmosetLighting( s, viewDir, lightDir, _LightColor0 * atten);
}

inline half4 LightingMarmosetDirect( MarmosetOutput s, half3 viewDir, UnityGI gi ) {
	fixed4 c;
	c = marmosetLighting (s, viewDir, gi.light.dir, gi.light.color);
	
	#if defined(DIRLIGHTMAP_SEPARATE)
		#ifdef LIGHTMAP_ON
			c += marmosetLighting (s, viewDir, gi.light2.dir, gi.light2.color);
		#endif
		#ifdef DYNAMICLIGHTMAP_ON
			c += marmosetLighting (s, viewDir, gi.light3.dir, gi.light3.color);
		#endif
	#endif

	#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
		c.rgb += s.Albedo * gi.indirect.diffuse;
	#endif
	return c;
}

inline void LightingMarmosetDirect_GI (MarmosetOutput s, UnityGIInput giInput, inout UnityGI gi) {
	gi = UnityGlobalIllumination(giInput, 1.0, s.Normal);
}

//directional lightmap lighting
inline half4 LightingMarmosetDirect_DirLightmap (MarmosetOutput s, fixed4 color, fixed4 scale, half3 viewDir, bool surfFuncWritesNormal, out half3 specColor) {
	UNITY_DIRBASIS
	half3 scalePerBasisVector;
	
	half3 lm;
	#ifdef MARMO_DIFFUSE_DIRECT
		lm = DirLightmapDiffuse (unity_DirBasis, color, scale, s.Normal, surfFuncWritesNormal, scalePerBasisVector);
	#else
		lm = half3(0.0,0.0,0.0);
		scalePerBasisVector = half3(1.0,1.0,1.0);
	#endif
	float spec;
	#ifdef MARMO_SPECULAR_DIRECT
		half3 lightDir = normalize (scalePerBasisVector.x * unity_DirBasis[0] + scalePerBasisVector.y * unity_DirBasis[1] + scalePerBasisVector.z * unity_DirBasis[2]);
		
		half3 h = normalize (lightDir + viewDir);
		float nh = saturate(dot (s.Normal, h));
		spec = 0.125 * pow (nh, s.Specular * 512.0); //*0.125 to match unity and tone down the crazy
		
		// specColor used outside in the forward path, compiled out in prepass
		specColor = s.SpecularRGB * spec;
		#ifdef MARMO_DIFFUSE_DIRECT
			specColor *= lm;
		#endif
	#else
		spec = 0.0;
		specColor = half3(0.0,0.0,0.0);
	#endif
	
	
	// spec from the alpha component is used to calculate specular
	// in the Lighting*_Prepass function, it's not used in forward
	half4 result;
	result.rgb = lm;
	result.a = spec;
	return result;
}

//deferred shading
inline half4 LightingMarmosetDirect_Deferred (MarmosetOutput s, half3 viewDir, UnityGI gi, out half4 outDiffuseOcclusion, out half4 outSpecSmoothness, out half4 outNormal) {
	outDiffuseOcclusion = float4( s.Albedo, 1.0 );
	#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
		outSpecSmoothness = half4(0.0, 0.0, 0.0, s.Specular*4.0); //HACK: we cannot turn off G-buffer reflections but we can minimize their effect at least, set specular to zero after this.
	#elif defined(MARMO_SPECULAR_DIRECT)
		outSpecSmoothness = half4(s.SpecularRGB * 0.125, s.Specular*4.0); //x0.125 to match Forward intensity, x4.0 to map to Forward specular exponent (Unity:128, Marmoset:512)
	#else
		outSpecSmoothness = half4(0.0, 0.0, 0.0, 1.0);
	#endif
	
	
	outNormal = half4(s.Normal * 0.5 + 0.5, 1.0);
	half4 emission = half4(s.Emission, 1.0);
	
	#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
		emission.rgb += s.Albedo * gi.indirect.diffuse;
	#endif
	return emission;
}

#endif