//
//  CSGamepad.m
//  Engine
//
//  Created by Aurora on 25/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import "CSGamepad.h"

@implementation CSGamepad {
  CSGamepadSubsystem * gamepadSubsystem;
  bool buttons[CS_BUTTON_COUNT];
}

@synthesize name;

- (nonnull instancetype) initWithSubsystem: (CSGamepadSubsystem *) subsystem {
  if (self = [super init]) {
    gamepadSubsystem = subsystem;

    [gamepadSubsystem addGamepad: self];
  }

  return self;
}

- (void) rawAxis: (NSInteger)axis withState: (float)state {
}

- (void) rawButton: (NSInteger)button withState: (NSInteger)state {
}

- (CSGamepadState) snapshot {
  uint16_t state = 0;

  for (int i = 0; i < CS_BUTTON_COUNT; i++) {
    if (buttons[i]) {
      state |= (1 << i);
    }
  }

  CSGamepadState result;
  memcpy(&result, &state, sizeof(state));
  return result;
}

- (void) updateButton: (NSInteger) button withState: (bool) state {
  if (buttons[button] != state) {
    buttons[button] = state;
  }
}

- (void) disconnect {
  [gamepadSubsystem removeGamepad: self];
}

@end
