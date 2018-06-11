// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: unity_Scale shader variable was removed; replaced 'unity_Scale.w' with '1.0'

#ifndef MARMO_TREE_LEAVES_CGINC
#define MARMO_TREE_LEAVES_CGINC

//#include "UnityBuiltin3xTreeLibrary.cginc"

struct Input {
	float2 uv_MainTex;
	float4 diffuseIBL : TEXCOORD2; //rgb - diffIBL, a - exposure.w
	#ifdef MARMO_SPECULAR_DIRECT
		float3 viewDir;
	#endif
	#ifdef MARMO_SPECULAR_IBL
		float3 worldRefl;
	#endif
	INTERNAL_DATA
};

void LeavesVert(inout appdata_full v, out Input o) {
	UNITY_INITIALIZE_OUTPUT(Input,o);
		
	ExpandBillboard (UNITY_MATRIX_IT_MV, v.vertex, v.normal, v.tangent);
	v.vertex.xyz *= _TreeInstanceScale.xyz;
	v.vertex = AnimateVertex (v.vertex,v.normal, float4(v.color.xy, v.texcoord1.xy));	
	v.vertex = Squash(v.vertex);	
	v.normal = normalize(v.normal);
	v.tangent.xyz = normalize(v.tangent.xyz);
	
	float3 worldN = mul((float3x3)unity_ObjectToWorld, v.normal * 1.0);	
	half4 exposureIBL = blendedExposure();
	o.diffuseIBL.rgb = blendedDiffuseIBL(worldN) * exposureIBL.x * v.color.a; //color.a is vertex AO
	o.diffuseIBL.a = exposureIBL.w; //camera exposure is propagated through color.a
}

//Direct Light
inline half4 LightingLeavesDirect (LeafSurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
	half nl = dot (s.Normal, lightDir);
	
	#ifdef MARMO_SPECULAR_DIRECT
		half3 h = normalize(lightDir + viewDir);
		half nh = saturate(dot(s.Normal, h));
		half spec = pow (nh, s.Specular * 128.0) * s.Gloss;
	#endif
	
	// view dependent back contribution for translucency
	fixed backContrib = saturate(dot(viewDir, -lightDir));
	
	// normally translucency is more like -nl, but looks better when it's view dependent
	backContrib = lerp(saturate(-nl), backContrib, _TranslucencyViewDependency);
	
	fixed3 translucencyColor = backContrib * s.Translucency * _TranslucencyColor;
	
	// wrap-around diffuse
	nl = saturate(nl * 0.6 + 0.4);
	
	fixed4 c;
	c.rgb = s.Albedo * (translucencyColor * 2 + nl);
	c.rgb = c.rgb * _LightColor0.rgb;
	c.a = s.Alpha;
	#ifdef MARMO_SPECULAR_DIRECT
		c.rgb += spec.xxx;
	#endif
	
	// For directional lights, apply less shadow attenuation
	// based on shadow strength parameter.
	#if defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE)
		c.rgb *= lerp(1.0, atten, _ShadowStrength);
	#else
		c.rgb *= 1.0*atten;
	#endif
	
	return c;
}

void LeavesSurf (Input IN, inout LeafSurfaceOutput o) {
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);	
	o.Albedo = c.rgb * _Color.rgb * IN.diffuseIBL.a;
	o.Alpha = c.a;
	
	float3 localN = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
	o.Normal = localN;
	
	o.Translucency = tex2D(_TranslucencyMap, IN.uv_MainTex).rgb;
	
	#if defined(MARMO_SPECULAR_DIRECT) || defined(MARMO_SPECULAR_IBL)
		float3 E = normalize(IN.viewDir); //E is in whatever space N is
		half fresnel = splineFresnel(localN, E, _SpecInt, _Fresnel);
		
		o.Specular = _Shininess;
		o.Gloss = tex2D(_GlossMap, IN.uv_MainTex).a;
		o.Gloss *= fresnel;
		o.Gloss *= c.a*c.a;
		o.Gloss *= IN.diffuseIBL.a;
		o.Gloss *= specEnergyScalar(o.Specular*128);
	#else
		o.Specular = 0.0;
		o.Gloss = 0.0;
	#endif
	
	o.Emission = IN.diffuseIBL * o.Albedo;
	
	#ifdef MARMO_SPECULAR_IBL
		//TODO.
	#endif
}

void OptLeavesSurf (Input IN, inout LeafSurfaceOutput o) {
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
	o.Albedo = c.rgb * _Color.rgb * IN.diffuseIBL.a;
	o.Alpha = c.a;
	
	half4 norspc = tex2D (_BumpSpecMap, IN.uv_MainTex);
	float3 localN = UnpackNormalDXT5nm(norspc);
	o.Normal = localN;
	
	fixed4 trngls = tex2D (_TranslucencyMap, IN.uv_MainTex);
	o.Translucency = trngls.b;
	
	#if defined(MARMO_SPECULAR_DIRECT) || defined(MARMO_SPECULAR_IBL)
		float3 E = normalize(IN.viewDir); //E is in whatever space N is
		half fresnel = splineFresnel(localN, E, _SpecInt, _Fresnel);
		
		o.Specular = norspc.r;
		o.Gloss = trngls.a * _Color.r;
		o.Gloss = 1.0;
		o.Specular = 0.25;		
		o.Gloss *= fresnel;
		o.Gloss *= c.a*c.a;
		o.Gloss *= specEnergyScalar(o.Specular*128);
		o.Gloss *= IN.diffuseIBL.a;
	#endif
		
	o.Emission = IN.diffuseIBL * o.Albedo;
}

#endif