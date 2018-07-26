//
//  CSRawrputer.m
//  Engine
//
//  Created by Aurora on 24/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import "CSRawrputer.h"
#import "CSGraphicsProcessor.h"
#import "CSGamepadSubsystem.h"

@implementation CSRawrputer {
  MTKView * metalView;
  CSGraphicsProcessor * graphics;
  CSGamepadSubsystem * gamepads;
}

- (CSGraphicsConfiguration *) graphicsConfiguration {
  return [graphics graphicsConfiguration];
}

- (CSGraphicsState *) graphicsState {
  return [graphics graphicsState];
}

- (CSColor *) palette {
  return [graphics palette];
}

- (void *) vram {
  return [graphics vram];
}

- (CSGamepadConfiguration *) gamepadConfiguration {
  return [gamepads gamepadConfiguration];
}

- (CSGamepadState *) gamepadState {
  return [gamepads gamepads];
}

- (void) viewDidAppear {
  [metalView.window makeFirstResponder: self];
}

- (void) viewDidLoad {
  [super viewDidLoad];

  interruptSemaphore = dispatch_semaphore_create(1);

  metalView = (MTKView *)self.view;
  metalView.device = MTLCreateSystemDefaultDevice();
  metalView.delegate = self;
  metalView.depthStencilPixelFormat = MTLPixelFormatDepth16Unorm;
  metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
  metalView.sampleCount = 1;

  if (!metalView.device) {
    NSLog(@"Metal is not supported on this device");
    self.view = [[NSView alloc] initWithFrame: self.view.frame];
    exit(1);
  }

  CSGraphicsConfiguration graphicsConfiguration = {
    .supported_backrounds = CS_BACKGROUND_COUNT,
    .supported_sprites = CS_SPRITE_COUNT,
    .palette_size = CS_PALETTE_SIZE * sizeof(CSColor),
    .vram_size = CS_VRAM_SIZE
  };

  graphics = [[CSGraphicsProcessor alloc] initWithGraphicsConfiguration: graphicsConfiguration andView: metalView];
  gamepads = [[CSGamepadSubsystem alloc] init];

  [self mtkView: metalView drawableSizeWillChange: metalView.bounds.size];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
    [self run];
  });
}

- (void) run {
  
}

- (void) vblank {
  
}

- (void) drawInMTKView: (nonnull MTKView *)view {
  __block dispatch_semaphore_t s = interruptSemaphore;

  if ([self graphicsState]->screen.enabled) {
    [graphics renderFrame: ^() {
      [self->gamepads strobe];
      [self vblank];
      dispatch_semaphore_signal(s);
    }];
  } else {
    dispatch_semaphore_signal(s);
  }
}

- (void) mtkView: (nonnull MTKView *)view drawableSizeWillChange: (CGSize)size {
  [graphics updateScreenSize: simd_make_ushort2(size.width, size.height)];
}

@end
