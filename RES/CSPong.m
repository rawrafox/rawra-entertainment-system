//
//  CSPong.m
//  Engine
//
//  Created by Aurora on 24/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import "CSPong.h"

void preparePalette(CSColor * palette);
void prepareVram(void * vram);

vector_short4 initializeBall(void);
void drawBall(CSSprite * sprite, vector_short2 position);
void drawPaddle(CSSprite * sprite, short position);

#define PADDLE_OFFSET 20
#define SCORE_OFFSET_X 120
#define SCORE_OFFSET_Y 170
#define SCREEN_X 384
#define SCREEN_Y 216
#define SCREEN simd_make_short2(SCREEN_X, SCREEN_Y)

@implementation CSPong {
  bool reset;

  vector_short4 ball;
  vector_short4 paddles;
}

- (void) run {
  reset = true;
  srand((uint32_t)time(nil));

  preparePalette([self palette]);
  prepareVram([self vram]);

  CSGraphicsState * state = [self graphicsState];
  CSGamepadState * gamepads = [self gamepadState];

  state->screen.size = simd_make_ushort2(SCREEN_X, SCREEN_Y);
  state->screen.background = 0;
  state->screen.border = 1;
  state->screen.debug = 2;

  state->backgrounds[0].type = 1;
  state->backgrounds[0].priority = 5;
  state->backgrounds[0].size = simd_make_ushort2(12, 7);
  state->backgrounds[0].position = simd_make_short2(0, -2);
  state->backgrounds[0].map = 128;
  state->backgrounds[0].tile = 64;
  state->backgrounds[0].palette = 32;

  state->sprites[0].type = 1;
  state->sprites[0].size = simd_make_ushort2(1, 3);
  state->sprites[0].position.x = PADDLE_OFFSET;
  state->sprites[0].priority = 10;
  state->sprites[0].palette = 16;
  state->sprites[0].tile = 0;

  state->sprites[1].type = 1;
  state->sprites[1].size = simd_make_ushort2(1, 3);
  state->sprites[1].position.x = SCREEN_X - PADDLE_OFFSET - 8;
  state->sprites[1].priority = 10;
  state->sprites[1].palette = 16;
  state->sprites[1].tile = 0;

  state->sprites[2].type = 1;
  state->sprites[2].size = simd_make_ushort2(1, 1);
  state->sprites[2].priority = 20;
  state->sprites[2].palette = 16;
  state->sprites[2].tile = 3;

  state->sprites[3].type = 1;
  state->sprites[3].size = simd_make_ushort2(2, 3);
  state->sprites[3].position.x = SCORE_OFFSET_X;
  state->sprites[3].position.y = SCORE_OFFSET_Y;
  state->sprites[3].priority = 5;
  state->sprites[3].palette = 32;
  state->sprites[3].tile = 4;

  state->sprites[4].type = 1;
  state->sprites[4].size = simd_make_ushort2(2, 3);
  state->sprites[4].position.x = SCREEN_X - SCORE_OFFSET_X - 16;
  state->sprites[4].position.y = SCORE_OFFSET_Y;
  state->sprites[4].priority = 5;
  state->sprites[4].palette = 32;
  state->sprites[4].tile = 4;

  state->screen.enabled = true;

  for (int frame = 0;; frame++) {
    if (reset) {
      reset = false;

      ball = initializeBall();
      paddles = simd_make_short4(SCREEN_Y * 4, SCREEN_Y * 4, 0, 0);
    }

    dispatch_semaphore_wait(interruptSemaphore, DISPATCH_TIME_FOREVER);

    ball.xy += ball.zw;
    paddles.xy += paddles.zw;


    if (gamepads[0].start || gamepads[1].start) {
      for (int i = 0; i < 10; i++) {
        dispatch_semaphore_wait(interruptSemaphore, DISPATCH_TIME_FOREVER);
      }

      while (!gamepads[0].start && !gamepads[1].start) {
        dispatch_semaphore_wait(interruptSemaphore, DISPATCH_TIME_FOREVER);
      }

      for (int i = 0; i < 10; i++) {
        dispatch_semaphore_wait(interruptSemaphore, DISPATCH_TIME_FOREVER);
      }
    }

    if (gamepads[0].select || gamepads[1].select) {
      for (int i = 0; i < 10; i++) {
        dispatch_semaphore_wait(interruptSemaphore, DISPATCH_TIME_FOREVER);
      }

      reset = true;
    }

    if (gamepads[0].up) {
      paddles.z = paddles.z < 0 ? 0 : paddles.z + 1;
    } else if (gamepads[0].down){
      paddles.z = paddles.z > 0 ? 0 : paddles.z - 1;
    } else {
      paddles.z = 0;
    }

    if (gamepads[1].up) {
      paddles.w = paddles.w < 0 ? 0 : paddles.w + 1;
    } else if (gamepads[1].down){
      paddles.w = paddles.w > 0 ? 0 : paddles.w - 1;
    } else {
      paddles.w = 0;
    }

    if (ball.x < 0 || (ball.x > (PADDLE_OFFSET * 8) && ball.x <= ((PADDLE_OFFSET + 8) * 8) && (ball.y + 63) > paddles.x && (ball.y - 63) < paddles.x + 24 * 8)) {
      ball.z = abs(ball.z);
    } else if (ball.x > (SCREEN_X - 8) * 8 || (ball.x >= (SCREEN_X - PADDLE_OFFSET - 8 - 8) * 8 && ball.x < (SCREEN_X - PADDLE_OFFSET - 8) * 8 && (ball.y + 63) > paddles.y && (ball.y - 63) < paddles.y + 24 * 8)) {
      ball.z = -abs(ball.z);
    }

    if (ball.y < 0) {
      ball.w = abs(ball.w);
    } else if (ball.y > (SCREEN_Y - 8) * 8) {
      ball.w = -abs(ball.w);
    }

    ball.xy = simd_clamp(ball.xy, simd_make_short2(0, 0), (SCREEN - 8) * 8);

    paddles.xy = simd_clamp(paddles.xy, 0, (SCREEN_Y - 24) * 8);
    paddles.zw = simd_clamp(paddles.zw, -32, 32);

    drawBall(&state->sprites[2], ball.xy);
    drawPaddle(&state->sprites[0], paddles.x);
    drawPaddle(&state->sprites[1], paddles.y);
  }
}

@end

vector_short4 initializeBall() {
  return simd_make_short4((SCREEN_X - 8) * 4, rand() % ((SCREEN_Y - 8) * 8), (1 - (2 * (rand() % 2))) * 12, rand() % 16 - 8);
}

void drawBall(CSSprite * sprite, vector_short2 position) {
  sprite->position = (position >> 3);
}

void drawPaddle(CSSprite * sprite, short position) {
  sprite->position.y = (position >> 3);
}

void preparePalette(CSColor * palette) {
  CSColor gamePalette[] = {
    CSColorFromRGB(0xFF, 0x20, 0x20), // Background
    CSColorFromRGB(0x00, 0x00, 0x00), // Border
    CSColorFromRGB(0xFF, 0x00, 0x00), // Debug
    CSColorFromRGB(0x00, 0x00, 0xFF), // Debug
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSColorFromRGB(0x00, 0x00, 0x00), // Sprites
    CSColorFromRGB(0xFF, 0xFF, 0xFF),
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent, // BG0
    CSColorFromRGB(0xFF, 0xFF, 0xFF),
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent,
    CSTransparent

  };

  memcpy(palette, &gamePalette, sizeof(gamePalette));
}

void prepareVram(void * vram) {
  uint8_t sprites[] = {
    0x01, 0x11, 0x11, 0x10, // Paddle
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x00, 0x11, 0x11, 0x00, // Ball
    0x01, 0x22, 0x22, 0x10,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x22, 0x22, 0x10,
    0x00, 0x11, 0x11, 0x00,
    0x11, 0x11, 0x11, 0x11, // Zero
    0x11, 0x11, 0x11, 0x11,
    0x11, 0x11, 0x11, 0x11,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x11, 0x11, 0x11,
    0x11, 0x11, 0x11, 0x11,
    0x11, 0x11, 0x11, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x10, 0x00, 0x00,
    0x11, 0x11, 0x11, 0x11,
    0x11, 0x11, 0x11, 0x11,
    0x11, 0x11, 0x11, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x00, 0x00, 0x01, 0x11,
    0x11, 0x11, 0x11, 0x11,
    0x11, 0x11, 0x11, 0x11,
    0x11, 0x11, 0x11, 0x11,
    0x01, 0x11, 0x11, 0x10, // One
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10, // Two
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10, // Three
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10, // Four
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10, // Five
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10, // Six
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10, // Seven
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10, // Eight
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10, // Nine
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x01, 0x11, 0x11, 0x10,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x12, 0x22, 0x22, 0x21,
    0x01, 0x11, 0x11, 0x10,
    0x00, 0x00, 0x00, 0x00, // BG tile 0
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x11, // BG tile 1
    0x00, 0x00, 0x00, 0x11,
    0x00, 0x00, 0x00, 0x11,
    0x00, 0x00, 0x00, 0x11,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x11, 0x00, 0x00, 0x00, // BG tile 2
    0x11, 0x00, 0x00, 0x00,
    0x11, 0x00, 0x00, 0x00,
    0x11, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
  };

  memcpy(vram, &sprites, sizeof(sprites));

  CSBackgroundMapEntry backgroundTile[] = {
    { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 1 },
    { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 1 },
    { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 1 },
    { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 1 },
    { 0, 0, 0, 0, 2 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 2 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 2 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 2 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 },
  };

  for (int i = 0; i < 7; i++) {
    memcpy(vram + CS_TILE_SIZE * (128 + i * 12 + 5), &backgroundTile, sizeof(backgroundTile));
  }
}