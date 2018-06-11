#ifndef MARMO_TREE_LEAVES_INPUT_CGINC
#define MARMO_TREE_LEAVES_INPUT_CGINC

//#include "TerrainEngine.cginc"

uniform sampler2D _MainTex;
uniform sampler2D _TranslucencyMap;

//uniform fixed4	_Color;
//uniform fixed4	_TranslucencyColor;
//uniform half	_TranslucencyViewDependency;
//uniform half	_ShadowStrength;
uniform float	_ShadowOffsetScale;
		
uniform sampler2D _BumpMap;
uniform sampler2D _GlossMap;
uniform half _Shininess;

uniform sampler2D _BumpSpecMap;

uniform half _SpecInt;
uniform half _Fresnel;

//uniform float4 _TreeInstanceScale;
//uniform half4 _TreeInstanceColor;
//uniform float _SquashAmount;
#endif

