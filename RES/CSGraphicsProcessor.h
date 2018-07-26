//
//  CSGraphicsProcessor.h
//  Engine
//
//  Created by Aurora on 24/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "rawrputer.h"

@interface CSGraphicsProcessor : NSObject

- (nonnull instancetype) initWithGraphicsConfiguration: (CSGraphicsConfiguration) graphicsConfiguration andView: (MTKView *) view;

@property (readonly) CSGraphicsConfiguration * graphicsConfiguration;
@property (readonly) CSGraphicsState * graphicsState;
@property (readonly) CSColor * palette;
@property (readonly) void * vram;

- (void) updateScreenSize: (vector_ushort2) size;
- (void) renderFrame: (CSInterrupt) vblank;

@end
