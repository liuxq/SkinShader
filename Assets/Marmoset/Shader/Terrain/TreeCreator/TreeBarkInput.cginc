#ifndef MARMO_TREE_BARK_INPUT_CGINC
#define MARMO_TREE_BARK_INPUT_CGINC

#include "TerrainEngine.cginc"

uniform sampler2D _MainTex;
uniform sampler2D _BumpMap;
uniform sampler2D _GlossMap;
uniform fixed4 _Color;
uniform half _Shininess;
uniform half _SpecInt;
uniform half _Fresnel;

//Optimized
uniform sampler2D _BumpSpecMap;
uniform sampler2D _TranslucencyMap;

uniform float _ShadowOffset; //ignored. needed by editor
#endif

