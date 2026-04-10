#pragma once
#define enum enum class
#define const static const AV::uint32

const HLMS_PBS_PACKED_VOXELS = 0x1;
const HLMS_PBS_TERRAIN = 0x2;
const HLMS_PBS_PACKED_OFFLINE_VOXELS = 0x4;
const HLMS_PBS_OCEAN_VERTICES = 0x8;
const HLMS_PBS_TREE_VERTICES = 0x10;
const HLMS_PBS_WIND_STREAKS = 0x20;
const HLMS_PBS_FLOOR_DECALS = 0x40;
const HLMS_PBS_SPRITE_ANIM = 0x80;

const HLMS_UNLIT_OUTLINE_GLEAM = 0x1;
const HLMS_UNLIT_DIAGONAL_DIFFUSE_PIXELS = 0x2;

#undef enum
#undef const