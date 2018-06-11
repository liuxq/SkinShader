#ifndef MARMOSET_TERRAIN_CGINC
#define MARMOSET_TERRAIN_CGINC

uniform sampler2D _BaseTex;
uniform float4    _BaseTex_ST;

uniform sampler2D _Control;
uniform float4    _Control_ST;

uniform sampler2D _Splat0,_Splat1,_Splat2,_Splat3;
uniform float4    _Splat0_ST,_Splat1_ST,_Splat2_ST,_Splat3_ST;

#ifdef MARMO_NORMALMAP
uniform sampler2D _BumpMap;
uniform float4    _BumpMap_ST;
#endif

#ifdef MARMO_NORMALMAP_DETAIL
uniform sampler2D _Normal0,_Normal1,_Normal2,_Normal3;
uniform float4    _Normal0_ST,_Normal1_ST,_Normal2_ST,_Normal3_ST;
#endif

uniform fixed4		_Color;
uniform half		_BaseWeight;
uniform half		_DetailWeight;

uniform half	 	_FadeNear;
uniform half		_FadeRange; //TODO: invFadeRange

uniform half		_SpecInt;
uniform half		_SpecInt0;
uniform half		_SpecInt1;
uniform half		_SpecInt2;
uniform half		_SpecInt3;

uniform half		_SpecFresnel;
uniform half		_Shininess;	//master gloss
uniform half		_Gloss0;
uniform half		_Gloss1;
uniform half		_Gloss2;
uniform half		_Gloss3;

uniform half		_DiffFresnel; //master fresnel
uniform half		_Fresnel0;
uniform half		_Fresnel1;
uniform half		_Fresnel2;
uniform half		_Fresnel3;

uniform half		_Fresnel4;
uniform half		_Fresnel5;
uniform half		_Fresnel6;
uniform half		_Fresnel7;

struct Input {
	float3 texcoord : TEXCOORD0;
	float3 worldNormal;
	#if defined(MARMO_DIFFUSE_FRESNEL) || defined(MARMO_SPECULAR_IBL)
		float3 viewDir;
	#endif
	INTERNAL_DATA
};

void MarmosetTerrainVert (inout appdata_full v, out Input o) {
	UNITY_INITIALIZE_OUTPUT(Input,o);
	o.texcoord.xy = v.texcoord.xy;
#ifdef MARMO_NORMALMAP
	v.tangent.xyz = cross(v.normal, float3(0.0,0.0,1.0));
	v.tangent.w = -1.0;
#endif
#if defined(MARMO_DIFFUSE_FRESNEL) || defined(MARMO_SPECULAR_IBL)
	float3 vpos = mul(UNITY_MATRIX_MV, v.vertex).xyz;
	o.texcoord.z = length(vpos);
#endif
}

void MarmosetTerrainSurf (Input IN, inout SurfaceOutput OUT) {
	#ifdef MARMO_SKY_BLEND
		half4 exposureIBL = lerp(_ExposureIBL1, _ExposureIBL, _BlendWeightIBL);
	#else
		half4 exposureIBL = _ExposureIBL;	
	#endif
	exposureIBL.xy *= _UniformOcclusion.xy;
	
	float2 uv_Control = TRANSFORM_TEX(IN.texcoord.xy, _Control);	
	float2 uv_Splat0 = TRANSFORM_TEX(IN.texcoord.xy, _Splat0);
	float2 uv_Splat1 = TRANSFORM_TEX(IN.texcoord.xy, _Splat1);
	float2 uv_Splat2 = TRANSFORM_TEX(IN.texcoord.xy, _Splat2);
	float2 uv_Splat3 = TRANSFORM_TEX(IN.texcoord.xy, _Splat3);

	half4 splat_control = tex2D(_Control, uv_Control);
	fixed splatSum = dot(splat_control, fixed4(1,1,1,1));
	
	fixed4 diffBase;
	#ifdef MARMO_DIFFUSE_BASE
		diffBase = tex2D(_BaseTex, uv_Control);
	#else
		diffBase = fixed4(1.0,1.0,1.0,1.0);
	#endif
	
	fixed4 diff;	
	diff  = splat_control.r * tex2D (_Splat0, uv_Splat0);
	diff += splat_control.g * tex2D (_Splat1, uv_Splat1);
	diff += splat_control.b * tex2D (_Splat2, uv_Splat2);
	diff += splat_control.a * tex2D (_Splat3, uv_Splat3);
	
	diff.rgb *= diffBase.rgb;
	diff.rgb *= _Color.rgb;
	diff.rgb *= exposureIBL.w; //camera exposure is built into OUT.Albedo	
	OUT.Albedo = diff.rgb;
	OUT.Alpha = 0.0;
	
	//NORMAL
	float3 localN;
	float3 worldN;
	#ifdef MARMO_NORMALMAP
		fixed4 nrm;
		fixed4 nrmBase;
		nrmBase = tex2D (_BumpMap, uv_Control);
		#ifdef MARMO_NORMALMAP_DETAIL
			nrm  = splat_control.r * tex2D (_Normal0, uv_Splat0);
			nrm += splat_control.g * tex2D (_Normal1, uv_Splat1);
			nrm += splat_control.b * tex2D (_Normal2, uv_Splat2);
			nrm += splat_control.a * tex2D (_Normal3, uv_Splat3);
			
			// Sum of our four splat weights might not sum up to 1, in
			// case of more than 4 total splat maps. Need to lerp towards
			// "flat normal" in that case.
			fixed4 flatNormal = fixed4(0.5,0.5,1,0.5); // this is "flat normal" in both DXT5nm and xyz*2-1 cases
		
			#ifdef MARMO_HQ
				//weight detail normalmap to flat right here
				nrm = lerp(flatNormal, nrm, splatSum*_DetailWeight);		
			#else
				nrm = lerp(flatNormal, nrm, splatSum);
			#endif	
			
			localN = UnpackNormal(nrm);
			float3 baseN = UnpackNormal(nrmBase);
				
			#ifdef MARMO_HQ
				//put detail normalmap into base normalmap's tangent-space
				float3 T = normalize(cross(float3(0.0,1.0,0.0), baseN));
				float3 B = normalize(cross(baseN,T));
				localN = T * localN.x + B * localN.y + baseN * localN.z;
			#else
				//quick n' dirty blend of details onto base normalmap
				localN = normalize(baseN + _DetailWeight*localN);
			#endif
		#else
			localN = normalize(UnpackNormal(nrmBase));
		#endif
		OUT.Normal = localN; //OUT.Normal is in tangent-space
		worldN = WorldNormalVector(IN,localN);
	#else
		worldN = IN.worldNormal;
		#ifdef MARMO_HQ
			worldN = normalize(worldN);
		#endif
		#if defined(UNITY_PASS_PREPASSFINAL)
			localN = float3(0.0,0.0,1.0);
			//localN and viewDir are in tangent-space
		#else
			localN = worldN;
			//localN and viewDir are in world-space
		#endif
	#endif

	//SPECULAR & FRESNEL FADE
	#if defined(MARMO_DIFFUSE_FRESNEL) || defined(MARMO_SPECULAR_IBL)
		half fade = IN.texcoord.z;
		fade = (fade - _FadeNear) / _FadeRange;
		fade = 1.0-saturate(fade); //TODO: can we get rid of this 1-?
		float3 E = normalize(IN.viewDir.xyz);
	#endif

	#if defined(MARMO_SPECULAR) || defined(MARMO_DIFFUSE_FRESNEL)
		float3 localE = IN.viewDir;
		#ifdef MARMO_HQ
			localE = normalize(localE);
		#endif
	#endif	
	//SPECULAR
	#ifdef MARMO_SPECULAR_IBL
		float3 R = reflect(E,worldN);		
		#ifdef MARMO_SKY_BLEND
			float3 R1 = R;
			R1 = skyRotate(_SkyMatrix1, R1); //per-fragment matrix multiply, expensive
		#endif
		R = skyRotate(_SkyMatrix,R); //per-fragment matrix multiply, expensive
		
		half specBlur = dot(splat_control, half4(_Gloss0,_Gloss1,_Gloss2,_Gloss3));
		half specMask = dot(splat_control, half4(_SpecInt0,_SpecInt1,_SpecInt2,_SpecInt3));
		specMask *= diff.a * _SpecInt;// * splatSum;
		
		half glossLod = glossLOD(specBlur, _Shininess);
		OUT.Specular = glossExponent(glossLod);
		
		//TODO: per layer specular fresnel
		float _fresnel = _SpecFresnel;		
		#ifdef MARMO_HQ
			half fresnel = splineFresnel(localN, localE, _SpecInt, _fresnel);
		#else
			//omitting normalize makes things darker, generally
			half fresnel = fastFresnel(localN, localE, _SpecInt, _fresnel);		
		#endif
		
		//camera exposure is built into OUT.Specular
		specMask *= fade * fresnel * exposureIBL.w;		
		OUT.Gloss = specMask * specEnergyScalar(OUT.Specular); //divide specular integral out of direct lighting
		OUT.Specular *= 0.00390625; //divide specular exponent by 256
	
		#ifdef MARMO_MIP_GLOSS
			half3 specIBL = glossCubeLookup(_SpecCubeIBL, R, glossLod);
		#else
			half3 specIBL = specCubeLookup(_SpecCubeIBL, R);
		#endif
		
		#ifdef MARMO_SKY_BLEND
			#ifdef MARMO_MIP_GLOSS
				half3 specIBL1 = glossCubeLookup(_SpecCubeIBL1, R1, glossLod);
			#else
				half3 specIBL1 = specCubeLookup(_SpecCubeIBL1, R1);
			#endif
			specIBL = lerp(specIBL1, specIBL, _BlendWeightIBL);
		#endif
		
		OUT.Emission = _SpecColor.rgb * specIBL * exposureIBL.y * specMask;
	#else
		OUT.Emission = half3(0.0,0.0,0.0);
	#endif
	
	//DIFFUSE
	#ifdef MARMO_DIFFUSE_IBL		
		float3 skyN = worldN;
		skyN = skyRotate(_SkyMatrix, skyN);
		skyN = normalize(skyN);
		half3 diffIBL = SHLookup(skyN);	
		
		#ifdef MARMO_SKY_BLEND
			skyN = worldN;
			skyN = skyRotate(_SkyMatrix1, skyN); //per-fragment matrix multiply, expensive
			skyN = normalize(skyN);
			half3 diffIBL1 = SHLookup1(skyN);		
			diffIBL = lerp(diffIBL1, diffIBL, _BlendWeightIBL);
		#endif
		
		#ifdef MARMO_DIFFUSE_FRESNEL
			#ifdef MARMO_FIRST_PASS
				half dfresnelMask = dot(splat_control, half4(_Fresnel0,_Fresnel1,_Fresnel2,_Fresnel3));
			#else
				half dfresnelMask = dot(splat_control, half4(_Fresnel4,_Fresnel5,_Fresnel6,_Fresnel7));
			#endif
			half dfresnel = saturate(dot(localN, localE));
			dfresnel = 1.0 - dfresnel;
			dfresnel = lerp(dfresnel*dfresnel*dfresnelMask, dfresnel, dfresnelMask);
			//HACK: modify albedo and direct lighting gets fresnel also
			OUT.Albedo.rgb *= 1.0 + dfresnel.xxx * fade * _DiffFresnel;
		#endif
		OUT.Emission += OUT.Albedo.rgb * diffIBL * exposureIBL.x;
	#endif
	OUT.Emission *= diffBase.a; //AO
}

#endif