//
//  CSGamepad.h
//  Engine
//
//  Created by Aurora on 25/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <IOKit/hid/IOHIDLib.h>

#import "CSGamepadSubsystem.h"

#define CS_BUTTON_COUNT 12
#define CS_BUTTON_LEFT 0
#define CS_BUTTON_RIGHT 1
#define CS_BUTTON_UP 2
#define CS_BUTTON_DOWN 3
#define CS_BUTTON_A 4
#define CS_BUTTON_B 5
#define CS_BUTTON_X 6
#define CS_BUTTON_Y 7
#define CS_BUTTON_L 8
#define CS_BUTTON_R 9
#define CS_BUTTON_START 10
#define CS_BUTTON_SELECT 11

@interface CSGamepad : NSObject

- (nonnull instancetype) initWithSubsystem: (CSGamepadSubsystem *) subsystem;

@property NSString * name;

- (CSGamepadState) snapshot;
- (void) updateButton: (NSInteger) button withState: (bool) state;
- (void) disconnect;

- (void) rawAxis: (NSInteger)axis withState: (float)state;
- (void) rawButton: (NSInteger) button withState: (NSInteger) state;

@end
