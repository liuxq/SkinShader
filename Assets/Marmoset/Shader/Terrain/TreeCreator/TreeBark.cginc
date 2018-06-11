// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: unity_Scale shader variable was removed; replaced 'unity_Scale.w' with '1.0'

#ifndef MARMO_TREE_BARK_CGINC
#define MARMO_TREE_BARK_CGINC

struct Input {
	float2 uv_MainTex;
	#ifndef MARMO_NORMALMAP
		float3 worldNormal;
	#endif
	#ifdef MARMO_SPECULAR_DIRECT
		float3 viewDir;
	#endif
	#ifdef MARMO_SPECULAR_IBL
		float3 worldRefl;
	#endif
	half4 diffuseIBL : TEXCOORD2; //rgb - diffIBL, a - exposure.w
	INTERNAL_DATA
};

void BarkVert (inout appdata_full v, out Input o) {
	UNITY_INITIALIZE_OUTPUT(Input,o);
	v.vertex.xyz *= _TreeInstanceScale.xyz;
	v.vertex = AnimateVertex(v.vertex, v.normal, float4(v.color.xy, v.texcoord1.xy));	
	v.vertex = Squash(v.vertex);	
	v.normal = normalize(v.normal);
	v.tangent.xyz = normalize(v.tangent.xyz); 
	
	float3 worldN = mul((float3x3)unity_ObjectToWorld, v.normal * 1.0);
	
	half4 exposureIBL = blendedExposure();
	o.diffuseIBL.rgb = blendedDiffuseIBL(worldN) * exposureIBL.x * v.color.a; //color.a is vertex AO
	o.diffuseIBL.a = exposureIBL.w; //camera exposure is propagated through color.a
}

void BarkSurf (Input IN, inout SurfaceOutput o) {
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
	
	o.Albedo = c.rgb * _Color.rgb * IN.diffuseIBL.a;
	o.Alpha = c.a;
	
	float3 localN;
	#ifdef MARMO_NORMALMAP
		localN = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));	
		o.Normal = localN;
	#else
		localN = IN.worldNomral;
	#endif
	
	#if defined(MARMO_SPECULAR_DIRECT) || defined(MARMO_SPECULAR_IBL)
		float3 E = normalize(IN.viewDir); //E is in whatever space N is
		half fresnel = splineFresnel(localN, E, _SpecInt, _Fresnel);
		
		o.Gloss = tex2D(_GlossMap, IN.uv_MainTex).a;
		o.Gloss *= IN.diffuseIBL.a;
		
		o.Specular = _Shininess;
		o.Gloss *= specEnergyScalar(o.Specular*128); 
		o.Gloss *= _SpecInt * fresnel;
	#endif
	
	o.Emission = IN.diffuseIBL.rgb * o.Albedo;
	
	#ifdef MARMO_SPECULAR_IBL
		//TODO: the rest of blending in here
		half4 exposureIBL = blendedExposure();
		float3 R = WorldReflectionVector(IN, localN);
		R = normalize(skyRotate(_SkyMatrix,R));
		float lod = glossLOD(o.Gloss, _Shininess * 6.0 + 2.0);
		o.Emission += glossCubeLookup(_SpecCubeIBL, R, lod) * exposureIBL.y * _SpecInt;
	#endif
}
	
void OptBarkSurf (Input IN, inout SurfaceOutput o) {
	half4 c = tex2D(_MainTex, IN.uv_MainTex);	
	o.Albedo = c.rgb * _Color.rgb * IN.diffuseIBL.a;	
	o.Alpha = c.a;
	
	#if defined(MARMO_NORMALMAP) || defined(MARMO_SPECULAR_DIRECT)
		half4 norspc = tex2D (_BumpSpecMap, IN.uv_MainTex);		
	#endif
	
	#ifdef MARMO_NORMALMAP
		
	#endif
	
	float3 localN;
	#ifdef MARMO_NORMALMAP
		localN = UnpackNormalDXT5nm(norspc);
		o.Normal = localN;
	#else
		localN = IN.worldNomral;
	#endif
	
	#if defined(MARMO_SPECULAR_DIRECT) || defined(MARMO_SPECULAR_IBL)
		float3 E = normalize(IN.viewDir); //E is in whatever space N is
		half fresnel = splineFresnel(localN, E, _SpecInt, _Fresnel);

		o.Specular = norspc.r;
		fixed4 trngls = tex2D (_TranslucencyMap, IN.uv_MainTex);
		o.Gloss = trngls.a * _Color.r;
		o.Gloss *= IN.diffuseIBL.a;		
		o.Gloss *= _SpecInt * fresnel;		
		o.Gloss *= specEnergyScalar(o.Specular*128);		
	#endif
	
	o.Emission = IN.diffuseIBL.rgb * o.Albedo;
	
	#ifdef MARMO_SPECULAR_IBL
		//TODO.
	#endif	
}

#endif