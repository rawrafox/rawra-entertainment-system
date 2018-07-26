//
//  CSGamepadSubsystem.h
//  Engine
//
//  Created by Aurora on 25/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "rawrputer.h"

@class CSGamepad;

@interface CSGamepadSubsystem : NSObject

@property (readonly) CSGamepadConfiguration * gamepadConfiguration;
@property (readonly) CSGamepadState * gamepads;

- (void) strobe;

- (void) addGamepad: (CSGamepad *) gamepad;
- (void) removeGamepad: (CSGamepad *) gamepad;

@end
