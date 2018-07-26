//
//  rawrputer.h
//
//  Created by Aurora on 22/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#ifndef rawrputer
#define rawrputer

#ifdef __METAL_VERSION__
using metal::uint8_t;
using metal::uint16_t;
using metal::uint32_t;
using metal::short2;
using metal::ushort2;
#define cs_constant constant const
#else
typedef void (^CSInterrupt)(void);

#define cs_constant const
#define short2 vector_short2
#define ushort2 vector_ushort2
#define uint2 vector_uint2
#define uint3 vector_uint3
#endif

#include <simd/simd.h>

#define CS_MAX_GAMEPADS 4
#define CS_BACKGROUND_COUNT 8
#define CS_SPRITE_COUNT 128
#define CS_PALETTE_SIZE 512
#define CS_VRAM_SIZE (128 * 1024)
#define CS_TILE_SIZE 32

typedef struct {
  uint8_t alpha : 1;
  uint8_t blue  : 5;
  uint8_t green : 5;
  uint8_t red   : 5;
} CSColor;

typedef struct {
  uint16_t vertical_flip : 1;
  uint16_t horizontal_flip : 1;
  uint16_t priority : 1;
  uint16_t palette : 3;
  uint16_t tile : 10;
} CSBackgroundMapEntry;

static cs_constant CSColor CSTransparent = { 0, 0, 0, 0 };

static inline CSColor CSColorFromRGB(uint8_t r, uint8_t g, uint8_t b) {
  CSColor color = {
    1,
    (uint8_t)(b >> 3),
    (uint8_t)(g >> 3),
    (uint8_t)(r >> 3)
  };

  return color;
}

typedef struct {
  uint16_t enabled : 1;
  uint16_t background;
  uint16_t border;
  uint16_t debug;
  ushort2 size;
} CSScreen;

typedef struct {
  uint16_t type;
  uint16_t priority;
  ushort2 size;
  short2 position;
  uint32_t map;
  uint32_t tile;
  uint16_t palette;
} CSBackground;

typedef struct {
  uint16_t type;
  uint16_t priority;
  ushort2 size;
  short2 position;
  uint32_t tile;
  uint16_t palette;
  uint16_t draw_origin : 1;
  uint16_t draw_border : 1;
  uint16_t origin;
  uint16_t border;
} CSSprite;

typedef struct {
  CSScreen screen;
  CSBackground backgrounds[CS_BACKGROUND_COUNT];
  CSSprite sprites[CS_SPRITE_COUNT];
} CSGraphicsState;

typedef struct {
  ushort2 screen_size;
  uint16_t supported_backrounds;
  uint16_t supported_sprites;
  uint32_t palette_size;
  uint32_t vram_size;
} CSGraphicsConfiguration;

typedef struct {
  uint16_t left : 1;
  uint16_t right : 1;
  uint16_t up : 1;
  uint16_t down : 1;
  uint16_t a : 1;
  uint16_t b : 1;
  uint16_t x : 1;
  uint16_t y : 1;
  uint16_t l : 1;
  uint16_t r : 1;
  uint16_t start : 1;
  uint16_t select : 1;
} CSGamepadState;

typedef struct {
  uint32_t gamepads : 4;
} CSGamepadConfiguration;

#endif // rawrputer

