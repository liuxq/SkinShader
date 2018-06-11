// Marmoset Skyshop
// Copyright 2013 Marmoset LLC
// http://marmoset.co

//rules for mobile shader permutations
//nothing fancy
#ifdef MARMO_HQ
#undef MARMO_HQ
#endif

//Mobile only needs sky rotation when box projection is enabled
//#if defined(MARMO_SKY_ROTATION) && !defined(MARMO_BOX_PROJECTION)
//#undef MARMO_SKY_ROTATION
//#endif

//Mobile GPUs do not get per-sampler texture tiling, everything uses Diffuse tiling parameters resolved in vertex shader
#ifndef MARMO_NO_TILING
#define MARMO_NO_TILING
#endif

//Mobile needs to conserve vertex interpolants so world position is derived from viewDir in the fragment shader
#ifdef MARMO_NORMALMAP
#define MARMO_COMPUTE_WORLD_POS
#endif

#ifndef MARMO_U5_WORLD_POS
#define MARMO_U5_WORLD_POS
#endif