//
//  CSRawrputer.h
//  Engine
//
//  Created by Aurora on 24/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "rawrputer.h"

@interface CSRawrputer : NSViewController <MTKViewDelegate> {
  dispatch_semaphore_t interruptSemaphore;
}

@property (readonly) CSGraphicsConfiguration * graphicsConfiguration;
@property (readonly) CSGraphicsState * graphicsState;
@property (readonly) CSColor * palette;
@property (readonly) void * vram;

@property (readonly) CSGamepadConfiguration * gamepadConfiguration;
@property (readonly) CSGamepadState * gamepadState;

@end
