//
//  CSGraphicsProcessor.m
//  Engine
//
//  Created by Aurora on 24/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import "CSGraphicsProcessor.h"

@implementation CSGraphicsProcessor {
  MTKView * view;

  id <MTLCommandQueue> commandQueue;

  CSGraphicsConfiguration graphicsConfiguration;

  id <MTLBuffer> graphicsState;
  id <MTLBuffer> palette;
  id <MTLBuffer> vram;

  id <MTLRenderPipelineState> pipelineState;
  id <MTLDepthStencilState> depthState;

}

- (nonnull instancetype) initWithGraphicsConfiguration: (CSGraphicsConfiguration) gc andView: (MTKView *) metalView {
  if (self = [super init]) {
    view = metalView;

    MTLDepthStencilDescriptor * depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionGreater;
    depthStateDesc.depthWriteEnabled = YES;
    depthState = [view.device newDepthStencilStateWithDescriptor: depthStateDesc];

    graphicsConfiguration = gc;

    graphicsState = [view.device newBufferWithLength: sizeof(CSGraphicsState) options: MTLResourceStorageModeShared];
    [graphicsState addDebugMarker: @"Graphics State" range: NSMakeRange(0, sizeof(CSGraphicsState))];

    palette = [view.device newBufferWithLength: CS_PALETTE_SIZE * sizeof(CSColor) options: MTLResourceStorageModeShared];
    [palette addDebugMarker: @"Palette" range: NSMakeRange(0, CS_VRAM_SIZE)];

    vram = [view.device newBufferWithLength: CS_VRAM_SIZE options: MTLResourceStorageModeShared];
    [vram addDebugMarker: @"VRAM" range: NSMakeRange(0, CS_VRAM_SIZE)];

    commandQueue = [view.device newCommandQueue];
  }

  return self;
}

- (void) updateScreenSize: (vector_ushort2)size {
  graphicsConfiguration.screen_size = size;

  NSError *error = NULL;

  id<MTLLibrary> defaultLibrary = [view.device newDefaultLibrary];

  MTLFunctionConstantValues * constants = [[MTLFunctionConstantValues alloc] init];

  [constants setConstantValue: &size type: MTLDataTypeUShort2 withName: @"screenSize"];

  id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName: @"vertexFullscreen" constantValues: constants error: &error];

  if (!vertexFunction) { NSLog(@"Failed to create vertex function, error %@", error); exit(1); }

  id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName: @"render" constantValues: constants error: &error];

  if (!fragmentFunction) { NSLog(@"Failed to create fragment function, error %@", error); exit(1); }

  MTLRenderPipelineDescriptor * pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineStateDescriptor.sampleCount = view.sampleCount;
  pipelineStateDescriptor.vertexFunction = vertexFunction;
  pipelineStateDescriptor.fragmentFunction = fragmentFunction;
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
  pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
  pipelineState = [view.device newRenderPipelineStateWithDescriptor: pipelineStateDescriptor error: &error];

  if (!pipelineState) { NSLog(@"Failed to create pipeline state, error %@", error); exit(1); }
}

- (void) renderFrame: (CSInterrupt)vblank {
  id <MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

  [commandBuffer addCompletedHandler: ^(id<MTLCommandBuffer> buffer) { vblank(); }];

  MTLRenderPassDescriptor * renderPassDescriptor = view.currentRenderPassDescriptor;
  renderPassDescriptor.depthAttachment.clearDepth = 0.0;
  renderPassDescriptor.stencilAttachment = nil;

  if (renderPassDescriptor != nil) {
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor: renderPassDescriptor];

    [renderEncoder setRenderPipelineState: pipelineState];
    [renderEncoder setDepthStencilState: depthState];
    [renderEncoder setVertexBuffer: graphicsState offset: 0 atIndex: 0];
    [renderEncoder setFragmentBuffer: graphicsState offset: 0 atIndex: 0];
    [renderEncoder setFragmentBuffer: palette offset: 0 atIndex: 1];
    [renderEncoder setFragmentBuffer: vram offset: 0 atIndex: 2];
    [renderEncoder drawPrimitives: MTLPrimitiveTypeTriangle vertexStart: 0 vertexCount: (1 + CS_BACKGROUND_COUNT + CS_SPRITE_COUNT) * 3];

    [renderEncoder endEncoding];
    [commandBuffer presentDrawable: view.currentDrawable];
  }

  [commandBuffer commit];
}

- (CSGraphicsConfiguration *) graphicsConfiguration {
  return &graphicsConfiguration;
}

- (CSGraphicsState *) graphicsState {
  return [graphicsState contents];
}

- (CSColor *) palette {
  return [palette contents];
}

- (void *) vram {
  return [vram contents];
}

@end
