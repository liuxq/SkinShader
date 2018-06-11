// Marmoset Skyshop
// Copyright 2014 Marmoset LLC
// http://marmoset.co

#ifndef MARMOSET_UBER_CGINC
#define MARMOSET_UBER_CGINC
	#if MARMO_SPECULAR_ON
		#define MARMO_SPECULAR_IBL
		#define MARMO_SPECULAR_DIRECT
		
		//this is handled through fallbacks
		//#if !SHADER_API_MOBILE
		#define MARMO_MIP_GLOSS
		//#endif
	
		#if MARMO_DIFFUSE_SPECULAR_COMBINED_ON
			#define MARMO_DIFFUSE_SPECULAR_COMBINED
		#endif
	#endif
			
	#if MARMO_DIFFUSE_ON
		#define MARMO_DIFFUSE_IBL
		#define MARMO_DIFFUSE_DIRECT
	#endif
	
	#if MARMO_BUMP_ON
		#ifndef MARMO_NORMALMAP
		#define MARMO_NORMALMAP
		#endif
	#endif
			
	#if MARMO_OCC_OCCLUSION_MAP
		#define MARMO_OCCLUSION		
	#elif MARMO_OCC_VERTEX_OCCLUSION
		#define MARMO_VERTEX_OCCLUSION		
	#elif MARMO_OCC_VERTEX_COLOR
		#define MARMO_VERTEX_COLOR		
	#endif
			
	#if MARMO_GLOW_ON		
		#define MARMO_GLOW
	#endif	
	
	#if MARMO_TRANS_FADE
		#define MARMO_ALPHA
	#endif
	
	#if MARMO_TRANS_GLASS
		#define MARMO_ALPHA
		#define MARMO_SIMPLE_GLASS
	#endif
	
	#if MARMO_ALPHA_TEST_ON
		#define MARMO_ALPHA_TEST
	#endif
	
	#if MARMO_SKY_BLEND_ON
		#define MARMO_SKY_BLEND
	#endif
		
	#if MARMO_BOX_PROJECTION_ON	
		#if !defined(MARMO_OCCLUSION) && !defined(MARMO_VERTEX_OCCLUSION) && !defined(MARMO_VERTEX_COLOR)
		#define MARMO_BOX_PROJECTION
		#endif
	#endif	
#endif