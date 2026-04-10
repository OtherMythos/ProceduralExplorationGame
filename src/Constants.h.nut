#pragma once
#define enum enum class
#define const static const AV::uint32

const HLMS_PACKED_VOXELS = 0x1;
const HLMS_TERRAIN = 0x2;
const HLMS_PACKED_OFFLINE_VOXELS = 0x4;
const HLMS_OCEAN_VERTICES = 0x8;
const HLMS_TREE_VERTICES = 0x10;
const HLMS_WIND_STREAKS = 0x20;
const HLMS_FLOOR_DECALS = 0x40;
const HLMS_SPRITE_ANIM = 0x80;

#undef enum
#undef const