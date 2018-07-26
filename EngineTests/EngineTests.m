//
//  EngineTests.m
//  EngineTests
//
//  Created by Aurora on 22/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ShaderTypes.h"

@interface EngineTests : XCTestCase

@end

@implementation EngineTests

- (void)testColorConversion {
  CSColor color;

  color = CSColorFromRGB(0x00, 0x00, 0x00);
  XCTAssert(color.red == 0);
  XCTAssert(color.green == 0);
  XCTAssert(color.blue == 0);
  XCTAssert(color.alpha == 1);

  color = CSColorFromRGB(0xF8, 0xF8, 0xF8);
  XCTAssert(color.red == 31);
  XCTAssert(color.green == 31);
  XCTAssert(color.blue == 31);
  XCTAssert(color.alpha == 1);
}

@end
