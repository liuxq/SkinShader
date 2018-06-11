// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: unity_Scale shader variable was removed; replaced 'unity_Scale.w' with '1.0'

// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

#ifndef MARMOSET_SURF_CGINC
#define MARMOSET_SURF_CGINC

//Enable this if you are using Livenda screenspace reflection in your project.
#define MARMO_LIVENDA_MODE 0

half3 blendedDiffuseIBL(float3 worldN) {
	float3 skyN = worldN;
	skyN = skyRotate(_SkyMatrix, skyN);
	skyN = normalize(skyN);
	
	#ifdef MARMO_DIFFUSE_SCATTER
		float3 band0, band1, band2;
		SHLookup(skyN, band0, band1, band2);
		float4 scatter = _Scatter * _ScatterColor;
		half3 diffIBL = SHConvolve(band0, band1, band2, scatter.rgb);
	#else
		half3 diffIBL = SHLookup(skyN);	
	#endif
	
	#ifdef MARMO_SKY_BLEND
		skyN = skyRotate(_SkyMatrix1, worldN);
		skyN = normalize(skyN);
		half3 diffIBL1 = SHLookup1(skyN);
		diffIBL = lerp(diffIBL1, diffIBL, _BlendWeightIBL);
	#endif
	return diffIBL;
}

void MarmosetVert(inout appdata_full v, out Input o) {
	UNITY_INITIALIZE_OUTPUT(Input,o);
	
	#ifdef MARMO_NO_TILING
		o.texcoord.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
	#else
		o.texcoord.xy = v.texcoord.xy;
	#endif
	
	#ifdef MARMO_PACKED_UV
		o.texcoord.zw = v.texcoord1.xy;
	#endif
	
	#if defined(MARMO_VERTEX_COLOR) || defined(MARMO_VERTEX_LAYER_MASK)
		o.color = v.color;
	#elif defined(MARMO_VERTEX_OCCLUSION)
		o.color = v.color.rg;
	#endif
		
	#if !defined(MARMO_COMPUTE_WORLD_POS)
		o.worldP.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
		//else worldP is computed in the fragment shader		
	#endif
	
	#ifdef MARMO_PACKED_VERTEX_OCCLUSION
		o.texcoord.zw = v.color.rg;
	#endif

	#ifdef MARMO_PACKED_VERTEX_COLOR			
		o.texcoord.zw = v.color.rg;
		o.worldP.w = v.color.b;
	#endif
	
	#ifdef MARMO_DIFFUSE_VERTEX_IBL
		float3 worldN = normalize(mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL));
		o.vertexIBL = blendedDiffuseIBL(worldN);
	#endif
	
	//NOTE: worldN is computed after this function is called regardless
}

void MarmosetSurf(Input IN, inout MarmosetOutput OUT) {
	
	#if defined(MARMO_PACKED_UV)
		#define INtexcoord0 IN.texcoord.xy
		#define INtexcoord1 IN.texcoord.zw
	#elif defined(MARMO_PACKED_VERTEX_COLOR) || defined(MARMO_PACKED_VERTEX_OCCLUSION)
		#define INtexcoord0 IN.texcoord.xy
		#define INtexcoord1 IN.texcoord.xy
		#define INvcolor_rg	IN.texcoord.zw
		#define INvcolor_b  IN.worldP.w
	#else
		//make sure we avoid a swizzle here, swizzles cause dependent texture reads
		#define INtexcoord0 IN.texcoord
		#define INtexcoord1 IN.texcoord
	#endif
	
	#if defined(MARMO_CUSTOM_TILING)
		#define uv_diff  (INtexcoord0 * _MainTexTiling.xy +  _MainTexTiling.zw)
		#define uv_diff1 (INtexcoord0 * _MainTex1Tiling.xy + _MainTex1Tiling.zw)
		#define uv_diff2 (INtexcoord0 * _MainTex2Tiling.xy + _MainTex2Tiling.zw)
		#define uv_diff3 (INtexcoord0 * _MainTex3Tiling.xy + _MainTex3Tiling.zw)
		
		#define uv_spec  (INtexcoord0 * _SpecTexTiling.xy +  _SpecTexTiling.zw)
		#define uv_spec1 (INtexcoord0 * _SpecTex1Tiling.xy + _SpecTex1Tiling.zw)
		#define uv_spec2 (INtexcoord0 * _SpecTex2Tiling.xy + _SpecTex2Tiling.zw)
		#define uv_spec3 (INtexcoord0 * _SpecTex3Tiling.xy + _SpecTex3Tiling.zw)
		
		#define uv_bump  (INtexcoord0 * _BumpMapTiling.xy +  _BumpMapTiling.zw)
		#define uv_bump1 (INtexcoord0 * _BumpMap1Tiling.xy + _BumpMap1Tiling.zw)
		#define uv_bump2 (INtexcoord0 * _BumpMap2Tiling.xy + _BumpMap2Tiling.zw)
		#define uv_bump3 (INtexcoord0 * _BumpMap3Tiling.xy + _BumpMap3Tiling.zw)
		
		#ifdef MARMO_TEXTURE_LAYER_MASK_UV1
			#define uv_mask  (INtexcoord1 * _LayerMaskTiling.xy + _LayerMaskTiling.zw)
		#else
			#define uv_mask  (INtexcoord0 * _LayerMaskTiling.xy + _LayerMaskTiling.zw)
		#endif
		
		#define uv_glow (INtexcoord0 * _IllumTiling.xy   + _IllumTiling.zw)
		#define uv_occ  (INtexcoord1 * _OccTexTiling.xy  + _OccTexTiling.zw)
		
	#elif defined(MARMO_NO_TILING)
		#define uv_diff  INtexcoord0
		#define uv_diff1 INtexcoord0
		#define uv_diff2 INtexcoord0
		#define uv_diff3 INtexcoord0
		
		#define uv_spec  INtexcoord0
		#define uv_spec1 INtexcoord0
		#define uv_spec2 INtexcoord0
		#define uv_spec3 INtexcoord0
		
		#define uv_bump  INtexcoord0
		#define uv_bump1 INtexcoord0
		#define uv_bump2 INtexcoord0
		#define uv_bump3 INtexcoord0
		
		#define uv_glow  INtexcoord0
		#define uv_occ   INtexcoord1
		
		#if defined(MARMO_TEXTURE_LAYER_MASK_UV1)
			#define uv_mask INtexcoord1
		#else
			#define uv_mask INtexcoord0
		#endif	
	
	#else
		#define uv_diff  TRANSFORM_TEX(INtexcoord0, _MainTex)
		#define uv_diff1 TRANSFORM_TEX(INtexcoord0, _MainTex1)
		#define uv_diff2 TRANSFORM_TEX(INtexcoord0, _MainTex2)
		#define uv_diff3 TRANSFORM_TEX(INtexcoord0, _MainTex3)
		
		#define uv_spec  TRANSFORM_TEX(INtexcoord0, _SpecTex)
		#define uv_spec1 TRANSFORM_TEX(INtexcoord0, _SpecTex1)
		#define uv_spec2 TRANSFORM_TEX(INtexcoord0, _SpecTex2)
		#define uv_spec3 TRANSFORM_TEX(INtexcoord0, _SpecTex3)
		
		#define uv_bump  TRANSFORM_TEX(INtexcoord0, _BumpMap)
		#define uv_bump1 TRANSFORM_TEX(INtexcoord0, _BumpMap1)
		#define uv_bump2 TRANSFORM_TEX(INtexcoord0, _BumpMap2)
		#define uv_bump3 TRANSFORM_TEX(INtexcoord0, _BumpMap3)
		
		#define uv_glow TRANSFORM_TEX(INtexcoord0, _Illum)
		#define uv_occ  TRANSFORM_TEX(INtexcoord1, _OccTex)
		
		#if defined(MARMO_TEXTURE_LAYER_MASK_UV1)
			#define uv_mask TRANSFORM_TEX(INtexcoord1, _LayerMask)
		#else
			#define uv_mask TRANSFORM_TEX(INtexcoord0, _LayerMask)
		#endif
	#endif

	#ifdef MARMO_SKY_BLEND
		float skyWeight = _BlendWeightIBL;
	#endif
	
	half4 exposureIBL = _ExposureIBL;
	#if LIGHTMAP_ON
		exposureIBL.xy *= _ExposureLM;
	#endif
	#ifdef MARMO_SKY_BLEND
		half4 exposureIBL1 = _ExposureIBL1;
		#if LIGHTMAP_ON
			exposureIBL1.xy *= _ExposureLM1;
		#endif		
		exposureIBL = lerp(exposureIBL1, exposureIBL, skyWeight);
	#endif
	
	exposureIBL.xy *= _UniformOcclusion.xy;
	half4 baseColor = _Color;
	#ifdef MARMO_VERTEX_COLOR
		baseColor *= IN.color;
	#endif
	
	#ifdef MARMO_PACKED_VERTEX_COLOR
		baseColor.rg *= INvcolor_rg;
		baseColor.b  *= INvcolor_b;
	#endif
	
	#if defined(MARMO_VERTEX_LAYER_MASK)
		half4 layerWeight = IN.color;
	#elif defined(MARMO_TEXTURE_LAYER_MASK)
		half4 layerWeight = tex2D(_LayerMask, uv_mask);
	#else
		half4 layerWeight = half4(1.0,0.0,0.0,0.0);
	#endif
	
	#if defined(MARMO_VERTEX_LAYER_MASK) || defined(MARMO_TEXTURE_LAYER_MASK)
		half layerSum = dot(layerWeight, half4(1.0,1.0,1.0,1.0));
		layerWeight /= max(1.0, layerSum);
	#endif

	#ifdef MARMO_DIFFUSE_SPECULAR_COMBINED
		half4 diffspec = half4(1.0,1.0,1.0,1.0);
	#endif
			
	//DIFFUSE
	#if defined(MARMO_DIFFUSE_DIRECT) || defined(MARMO_DIFFUSE_IBL)
		//Layered diffuse
		#if defined(MARMO_DIFFUSE_4_LAYER)
			//TODO: per-pixel weight normalize here?
			half4 diff;
			diff  = layerWeight.r * tex2D( _MainTex,  uv_diff ) * baseColor;
			diff += layerWeight.g * tex2D( _MainTex1, uv_diff1 ) * _Color1;
			diff += layerWeight.b * tex2D( _MainTex2, uv_diff2 ) * _Color2;
			diff += layerWeight.a * tex2D( _MainTex3, uv_diff3 ) * _Color3;
		#elif defined(MARMO_DIFFUSE_2_LAYER)
			half4 diff;
			diff  = layerWeight.r * tex2D( _MainTex,  uv_diff ) * baseColor;
			diff += layerWeight.g * tex2D( _MainTex1, uv_diff1 ) * _Color1;
		#else
			half4 diff = tex2D( _MainTex, uv_diff ) * baseColor;
		#endif
		
		#ifdef MARMO_DIFFUSE_SPECULAR_COMBINED
			diffspec = diff.aaaa;
		#endif
		
		#ifdef MARMO_DIFFUSE_GLOW_COMBINED
			half3 diffglow = diff.rgb * diff.a;
		#endif
				
		//NOTE: this was the old way of doing it to separate vertex and base color from combined diff-spec alpha
		//diff *= baseColor;
		
		//camera exposure is built into OUT.Albedo
		diff.rgb *= exposureIBL.w;
		#ifdef MARMO_SIMPLE_GLASS
			diff.rgb *= diff.a;
		#endif
		OUT.Albedo = diff.rgb;		
		OUT.Alpha = diff.a;
	#else	
		#ifdef MARMO_DIFFUSE_DIRECT
			OUT.Albedo = baseColor.rgb;
		#else
			// we don't want any lights if direct diffuse is turned off
			OUT.Albedo = half3(0.0,0.0,0.0);
		#endif
		OUT.Alpha = baseColor.a;
		#ifdef MARMO_SIMPLE_GLASS
			OUT.Albedo.rgb *= baseColor.a;
		#endif
		#ifdef MARMO_DIFFUSE_GLOW_COMBINED
			half3 diffglow = baseColor.rgb * baseColor.a;
		#endif		
	#endif
	
	#ifdef MARMO_ALPHA_CLIP
		clip(OUT.Alpha - _Cutoff);
	#endif
	
	//AMBIENT OCC
	//#define MARMO_DIFF_OCCLUSION
	#if defined(MARMO_VERTEX_OCCLUSION) || defined(MARMO_OCCLUSION) || defined(MARMO_PACKED_VERTEX_OCCLUSION)
		half4 occ = half4(1.0,1.0,1.0,1.0);
		#ifdef MARMO_OCCLUSION
			occ = tex2D(_OccTex, uv_occ);
		#endif
		
		#ifdef MARMO_VERTEX_OCCLUSION
			occ.rg *= IN.color.rg;
		#endif
		
		#ifdef MARMO_PACKED_VERTEX_OCCLUSION
			occ.rg *= INvcolor_rg;
		#endif
		occ = lerp(half4(1.0,1.0,1.0,1.0),occ, _OccStrength);
		//TODO: occlude lightprobe SH by diffuse AO
		exposureIBL.xy *= occ.rg;
			
	#elif defined(MARMO_DIFF_OCCLUSION) && !defined(MARMO_ALPHA)
		//use diffuse alpha component to do ambient occlusion
		half2 docc = half2(diff.a, saturate(0.5 + diff.a));
		docc.y *= docc.y;
		docc.y *= docc.y;
		docc.y *= docc.y;
		exposureIBL.xy *= docc;
	#endif
	
	//NORMALS	
	#ifdef MARMO_NORMALMAP
		#if defined(MARMO_NORMALMAP_4_LAYER)
			half4 norm;
			norm  = layerWeight.r * tex2D( _BumpMap,  uv_bump );
			norm += layerWeight.g * tex2D( _BumpMap1, uv_bump1 );
			norm += layerWeight.b * tex2D( _BumpMap2, uv_bump2 );
			norm += layerWeight.a * tex2D( _BumpMap3, uv_bump3 );
			float3 localN = UnpackNormal(norm);
			localN = normalize(localN);
		#elif defined(MARMO_NORMALMAP_3_LAYER)
			half4 norm;
			norm  = layerWeight.r * tex2D( _BumpMap,  uv_bump );
			norm += layerWeight.g * tex2D( _BumpMap1, uv_bump1 );
			norm += layerWeight.b * tex2D( _BumpMap2, uv_bump2 );
			float3 localN = UnpackNormal(norm);
			localN = lerp(localN, float3(0.0,0.0,1.0), layerWeight.a);
			localN = normalize(localN);
		#elif defined(MARMO_NORMALMAP_2_LAYER)
			half4 norm;
			norm  = layerWeight.r * tex2D( _BumpMap,  uv_bump );
			norm += layerWeight.g * tex2D( _BumpMap1, uv_bump1 );
			float3 localN = UnpackNormal(norm);
			localN = lerp(localN, float3(0.0,0.0,1.0), layerWeight.b + layerWeight.a);
			localN = normalize(localN);
		#else
			float3 localN = UnpackNormal(tex2D( _BumpMap, uv_bump ));
			localN = normalize(localN);
		#endif
		//localN and viewDir are in tangent-space
		OUT.Normal = localN;
		float3 worldN = WorldNormalVector(IN,localN);
	#else
		float3 worldN = IN.worldNormal.xyz;
		worldN = normalize(worldN);
		#if defined(UNITY_PASS_PREPASSFINAL)
			float3 localN = float3(0.0,0.0,1.0);
			//localN and viewDir are in tangent-space
		#else
			float3 localN = worldN;
			//localN and viewDir are in world-space
		#endif
	#endif
	
	//SPECULAR
	#if defined(MARMO_SPECULAR_DIRECT) || defined(MARMO_SPECULAR_IBL)
		#ifdef MARMO_DIFFUSE_SPECULAR_COMBINED
			half4 spec = diffspec;			
		#else
			#if defined(MARMO_SPECULAR_4_LAYER)
				half4 spec;
				spec  = layerWeight.r * tex2D( _SpecTex,  uv_spec );
				spec += layerWeight.g * tex2D( _SpecTex1, uv_spec1 );
				spec += layerWeight.b * tex2D( _SpecTex2, uv_spec2 );
				spec += layerWeight.a * tex2D( _SpecTex3, uv_spec3 );
			#elif defined(MARMO_SPECULAR_3_LAYER)
				half4 spec;
				spec  = layerWeight.r * tex2D( _SpecTex,  uv_spec );
				spec += layerWeight.g * tex2D( _SpecTex1, uv_spec1 );
				spec += layerWeight.b * tex2D( _SpecTex2, uv_spec2 );
			#elif defined(MARMO_SPECULAR_2_LAYER)
				half4 spec;
				spec  = layerWeight.r * tex2D( _SpecTex,  uv_spec );
				spec += layerWeight.g * tex2D( _SpecTex1, uv_spec1 );
			#else
				half4 spec = tex2D( _SpecTex, uv_spec );
			#endif
		#endif
		
		//fresnel layering
		#if defined(MARMO_SPECULAR_4_LAYER)
			half4 fresnelLayers = half4(_Fresnel, _Fresnel1, _Fresnel2, _Fresnel3);				
			half _fresnel = dot(layerWeight, fresnelLayers);
		#elif defined(MARMO_SPECULAR_3_LAYER)
			half3 fresnelLayers = half3(_Fresnel, _Fresnel1, _Fresnel2);
			half _fresnel = dot(layerWeight.rgb, fresnelLayers.rgb);
		#elif defined(MARMO_SPECULAR_2_LAYER)
			half2 fresnelLayers = half2(_Fresnel, _Fresnel1);
			half _fresnel = dot(layerWeight.rg, fresnelLayers.rg);
		#else
			half _fresnel = _Fresnel;
		#endif
		
		float3 localE = normalize(IN.viewDir.xyz);				
		
		//Note: localE is good enough for an H, convolved light math can't come up with a good H
		half3 schlickF = schlickFresnel(localN, localE, _SpecInt, _fresnel);
		#if defined(MARMO_SPECULAR_FILTER)
			#define fresnel    schlickF.x
			#define oldFresnel schlickF.y
			#define specInt    schlickF.z
		#else
			#define fresnel schlickF.y			
		#endif
		
		#if defined(MARMO_HQ)
		//	half fresnel = splineFresnel(localN, localE, _SpecInt, _fresnel);
		#else
		//	half fresnel = fastFresnel(localN, localE, _SpecInt, _fresnel);		
		#endif
		
		//filter the light that reaches diffuse reflection by specular intensity
		#ifdef MARMO_SPECULAR_FILTER
			spec.rgb *= _SpecColor.rgb;
			half4 specPBR = spec * half4(specInt,specInt,specInt,1.0);
			//Light reaching diffuse is filtered by 1-specColor
			OUT.Albedo = saturate(OUT.Albedo - specPBR.rgb);
			//OUT.Albedo = saturate((-_PBR * specPBR.rgb) + OUT.Albedo);
			
			//Fresnel always goes to max white at the edges.
			//Gloss also gets smoother at the edges, grazing mountain-tops etc.
			spec = lerp(specPBR, half4(1.0,1.0,1.0,1.0), fresnel);
			//spec.rgb *= oldFresnel;
			//spec = lerp(spec, specPBR, _PBR);
		#else			
			spec.rgb *= fresnel;
			spec.rgb *= _SpecColor.rgb;
		#endif
		//camera exposure is built into OUT.Specular
		spec.rgb *= exposureIBL.w;
		half glossLod = glossLOD(spec.a, _Shininess);		
		#ifdef MARMO_SPECULAR_DIRECT
			OUT.SpecularRGB = spec.rgb;
			OUT.Specular = glossExponent(glossLod);
			//conserve energy by dividing out specular integral (direct lighting only)
			OUT.SpecularRGB *= specEnergyScalar(OUT.Specular);
			OUT.Specular *= 0.00390625; // 1/256
		#endif
	#endif
	
	//GLOW
	#if defined(MARMO_DIFFUSE_GLOW_COMBINED)
		half3 glow = diffglow.rgb * _EmissionColor.rgb;
		glow.rgb *= exposureIBL.w * _EmissionLM;
		OUT.Emission += glow.rgb;
	#elif defined(MARMO_GLOW)
		half4 glow = tex2D(_Illum, uv_glow);
		#ifdef MARMO_SIMPLE_GLASS
			glow *= OUT.Alpha;
		#endif		
		glow.rgb *= _GlowColor.rgb;
		glow.rgb *= _GlowStrength;
		glow.rgb *= exposureIBL.w;
		glow.a *= _EmissionLM;
		//NOTE: camera exposure is already in albedo from above
		glow.rgb += OUT.Albedo * glow.a;		
		OUT.Emission += glow.rgb;
	#endif
		
	//SPECULAR IBL
	#ifdef MARMO_SPECULAR_IBL		
		#ifdef MARMO_COMPUTE_WORLD_POS
			float3 worldE = IN.viewDir;
			//NOTE: This needs to happen for non-bumped directional lightmaps as well,
			// but cannot because Unity does not interpolate tangent space without bump. 
			// The problem is ignored because we don't need to compute worldPos in
			// non-bumped shaders.
			#ifdef MARMO_NORMALMAP
				worldE = WorldNormalVector(IN, worldE);
				worldE /= 1.0;
			#endif			
			#ifdef MARMO_U5_WORLD_POS
				float3 worldP = IN.worldPos; //this is free in Unity 5
			#else
				float3 worldP = _WorldSpaceCameraPos - worldE; //this doesn't work in Unity 5?
			#endif
			worldE = normalize(worldE);		
		#else
			float3 worldP = IN.worldP.xyz;
			float3 worldE = _WorldSpaceCameraPos - worldP;
			worldE = normalize(worldE);
		#endif
		
		#ifdef MARMO_SPECULAR_REFRACTION
			float4 worldF = specularRefract(-worldE, worldN, fresnel);
			float3 skyR = worldF.xyz;
			
			//lerp reflection color to white and refraction color to specular RGB
			spec.rgb = lerp(half3(_SpecInt,_SpecInt,_SpecInt), spec.rgb, worldF.w);
		#else 
			float3 skyR = reflect(-worldE, worldN);
		#endif
		
		#ifdef MARMO_SKY_BLEND
			float3 skyR1 = skyR;
			skyR1 = skyProject(_SkyMatrix1, _InvSkyMatrix1, _SkyMin1, _SkyMax1, worldP, skyR1);
		#endif
				
		skyR = skyProject(_SkyMatrix, _InvSkyMatrix, _SkyMin, _SkyMax, worldP, skyR);
	
		#ifdef MARMO_MIP_GLOSS
			half3 specIBL = glossCubeLookup(_SpecCubeIBL, skyR, glossLod);
		#else
			half3 specIBL =  specCubeLookup(_SpecCubeIBL, skyR)*spec.a;
		#endif
		
		#ifdef MARMO_SKY_BLEND
			#ifdef MARMO_MIP_GLOSS
				half3 specIBL1 = glossCubeLookup(_SpecCubeIBL1, skyR1, glossLod);
			#else
				half3 specIBL1 =  specCubeLookup(_SpecCubeIBL1, skyR1)*spec.a;
			#endif
			specIBL = lerp(specIBL1, specIBL, skyWeight);
		#endif
		OUT.Emission += specIBL.rgb * spec.rgb * exposureIBL.y;
	#endif
	
	//PEACH-FUZZ
	#ifdef MARMO_DIFFUSE_FUZZ
		float eyeDP = dot(localE, localN);			
		eyeDP = 1.0 - eyeDP;
		float dp4 = eyeDP * eyeDP; dp4 *= dp4;
		float fuzz = _Fuzz * lerp(dp4, eyeDP*0.4, _FuzzScatter); //0.4 is energy conserving integral
		
		//HACK: modify albedo and direct lighting gets fresnel also
		OUT.Albedo.rgb *= 1.0 + fuzz * _FuzzColor.rgb;
	#endif
	
	//DIFFUSE IBL
	#ifdef MARMO_DIFFUSE_VERTEX_IBL
		//diffuseIBL comes from vertex shader
		OUT.Emission += IN.vertexIBL * OUT.Albedo.rgb * exposureIBL.x;
	#else
		//per-fragment diffuse lookup
		half3 diffIBL = blendedDiffuseIBL(worldN);
		OUT.Emission += diffIBL * OUT.Albedo.rgb * exposureIBL.x;
	#endif

	#ifndef MARMO_ALPHA
        #if defined(MARMO_LIVENDA_MODE) && (defined(MARMO_SPECULAR_DIRECT) || defined(MARMO_SPECULAR_IBL))
            OUT.Alpha = dot(half3(0.3,0.59,0.11), spec.rgb); //grayscale specular intensity
        #else
            OUT.Alpha = 1.0;
        #endif
    #endif
}

#endif