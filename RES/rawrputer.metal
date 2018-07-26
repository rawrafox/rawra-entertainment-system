//
//  Shaders.metal
//  Engine
//
//  Created by Aurora on 22/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

#import "rawrputer.h"

using namespace metal;

constant ushort2 screenSize [[function_constant(0)]];

typedef struct {
  float4 position [[position]];
  float2 pixel;
  uint8_t type;
  uint8_t offset;
} RasterizerData;

typedef struct {
  half4 color [[color(0)]];
} FragmentData;

cs_constant float4 triangle[] = {
  float4(-1.0,  3.0, 0.0, 1.0),
  float4(-1.0, -1.0, 0.0, 1.0),
  float4( 3.0, -1.0, 0.0, 1.0)
};

cs_constant float2 spriteTriangle[] {
  float2(0.0, 2.0),
  float2(0.0, 0.0),
  float2(2.0, 0.0)
};

float priorityToDepth(uint16_t x) {
  return (float)(x + 1) / ((1 << 16) - 1);
}

ushort scaleFactor(constant CSGraphicsState & registers) {
  ushort2 scaleFactors = screenSize / registers.screen.size;

  return min(scaleFactors.x, scaleFactors.y);
}

float2 positionToPixel(constant CSGraphicsState & registers, float4 position) {
  ushort scale = scaleFactor(registers);
  ushort2 offset = (screenSize - (registers.screen.size * scale)) / 2;

  float2 sample = (position.xy + 1.0f) * 0.5f;
  float2 physicalPixel = (sample * static_cast<float2>(screenSize)) - static_cast<float2>(offset);

  return physicalPixel / scale;
}

float2 pixelToPosition(constant CSGraphicsState & registers, short2 pixel) {
  ushort scale = scaleFactor(registers);
  ushort2 offset = (screenSize - (registers.screen.size * scale)) / 2;

  float2 physicalPixel = static_cast<float2>(scale * pixel) + static_cast<float2>(offset);

  return (physicalPixel / static_cast<float2>(screenSize)) * 2.0f - 1.0f;
}

vertex RasterizerData vertexFullscreen(constant CSGraphicsState & registers [[buffer(0)]], unsigned int vertex_id [[vertex_id]]) {
  RasterizerData data;

  if (vertex_id < 3) {
    data.type = 0;
    data.position = triangle[vertex_id % 3];
    data.position.z = priorityToDepth(0);
    data.pixel = positionToPixel(registers, data.position);
    return data;
  } else if (vertex_id < ((1 + CS_BACKGROUND_COUNT) * 3)) {
    data.type = 1;
    data.offset = vertex_id / 3 - 1;

    if (registers.backgrounds[data.offset].type != 0) {
      data.position = triangle[vertex_id % 3];
      data.position.z = priorityToDepth(registers.backgrounds[data.offset].priority);
      data.pixel = positionToPixel(registers, data.position);
    } else {
      data.position = float4(0.0f, 0.0f, 0.0f, 0.0f);
    }
  } else if (vertex_id < ((1 + CS_BACKGROUND_COUNT + CS_SPRITE_COUNT) * 3)) {
    data.type = 2;
    data.offset = vertex_id / 3 - 1 - CS_BACKGROUND_COUNT;

    CSSprite sprite = registers.sprites[data.offset];

    if (sprite.type != 0) {
      float2 origin = pixelToPosition(registers, sprite.position);
      float2 size = static_cast<float2>(sprite.size * 8);

      data.position.xy = origin + spriteTriangle[vertex_id % 3] * size * 2.0f * scaleFactor(registers) / static_cast<float2>(screenSize);
      data.position.z = priorityToDepth(sprite.priority);
      data.position.w = 1.0f;
      data.pixel = positionToPixel(registers, data.position);
    } else {
      data.position = float4(0.0f, 0.0f, 0.0f, 0.0f);
    }
  } else {
    data.type = 0xFF; // FIXME: Reaching here is a bug
  }

  data.pixel = positionToPixel(registers, data.position);

  return data;
}

half4 colorToFloat(CSColor color) {
  half red = (half)color.red / 31;
  half green = (half)color.green / 31;
  half blue = (half)color.blue / 31;
  half alpha = (half)color.alpha;

  return half4(red, green, blue, alpha);
}

FragmentData discard() {
  discard_fragment();

  FragmentData data = { .color = half4(0.0f, 0.0f, 0.0f, 0.0f) };

  return data;
}

FragmentData renderScreen(constant CSColor * palette, uint32_t offset) {
  FragmentData data = { .color = colorToFloat(palette[offset]) };

  return data;
}

FragmentData renderBackground(constant CSColor * palette, constant void * vram, CSBackground background, float2 pixel) {
  float2 position = static_cast<float2>(background.position);

  if (background.type == 1) {
    float2 size = static_cast<float2>((ushort2)(32, 32) * background.size);

    if (all(pixel > position) && all(pixel < (position + size))) {
      uint2 offset = static_cast<uint2>(pixel - position);

      uint2 map_coordinates = (offset >> 5);
      uint map_offset = map_coordinates.x + (background.size.y - map_coordinates.y - 1) * background.size.x;
      uint2 map_entry_coordinates = (offset % uint2(32, 32)) >> 3;
      uint map_entry_offset = map_entry_coordinates.x + 4 * map_entry_coordinates.y;

      CSBackgroundMapEntry map_entry = ((constant CSBackgroundMapEntry *)vram)[16 * (background.map + map_offset) + map_entry_offset];

      constant uint8_t * tile_pointer = (constant uint8_t *)vram + CS_TILE_SIZE * (background.tile + map_entry.tile);

      uint2 pixel_coordinates = offset % uint2(8, 8);
      uint pixel_number = pixel_coordinates.x + (7 - pixel_coordinates.y) * 8;

      uint palette_index = tile_pointer[pixel_number / 2];

      if (pixel_number % 2 == 1) {
        palette_index &= 0x0F;
      } else {
        palette_index >>= 4;
      }

      CSColor color = palette[background.palette + (map_entry.palette << 4) + palette_index];

      if (color.alpha == 0) {
        return discard();
      }

      FragmentData data = { .color = colorToFloat(color) };

      return data;
    }
  }

  return discard();
}

FragmentData renderSprite(constant CSColor * palette, constant void * vram, CSSprite sprite, float2 pixel) {
  float2 position = static_cast<float2>(sprite.position);

  if (sprite.type == 1) {
    float2 size = static_cast<float2>((ushort2)(8, 8) * sprite.size);

    if (all(pixel >= position) && all(pixel < (position + size))) {
      uint2 offset = static_cast<uint2>(pixel - position);
      uint2 pixel = offset % (uint2)(8, 8);
      uint pixel_number = pixel.x + (7 - pixel.y) * 8;

      uint2 tile = offset / (uint2)(8, 8);
      uint tile_number = tile.x + (sprite.size.y - tile.y - 1) * sprite.size.x;
      constant uint8_t * tile_pointer = (constant uint8_t *)vram + CS_TILE_SIZE * (sprite.tile + tile_number);

      uint palette_index = tile_pointer[pixel_number / 2];

      if (pixel_number % 2 == 1) {
        palette_index &= 0x0F;
      } else {
        palette_index >>= 4;
      }

      CSColor color = palette[sprite.palette + palette_index];

      if (sprite.draw_origin && all(offset == (uint2)(0, 0))) {
        color = palette[sprite.origin];
      } else if (sprite.draw_border && (any(offset == (uint2)(0, 0)) || any(offset == static_cast<uint2>(sprite.size * 8 - 1)))) {
        color = palette[sprite.border];
      } else if (color.alpha == 0) {
        return discard();
      }

      FragmentData data = { .color = colorToFloat(color) };

      return data;
    }
  }

  return discard();
}

fragment FragmentData render(constant CSGraphicsState & registers [[buffer(0)]], constant CSColor * palette [[buffer(1)]], constant void * vram [[buffer(2)]], RasterizerData in [[stage_in]]) {
  if (any(in.pixel < (float2)(0.0f, 0.0f)) || any(in.pixel > static_cast<float2>(registers.screen.size)))  {
    return renderScreen(palette, registers.screen.border);
  } else {
    switch (in.type) {
      case 0: return renderScreen(palette, registers.screen.background);
      case 1: return renderBackground(palette, vram, registers.backgrounds[in.offset], in.pixel);
      case 2: return renderSprite(palette, vram, registers.sprites[in.offset], in.pixel);
      default:
        return discard();
    }
  }
}
