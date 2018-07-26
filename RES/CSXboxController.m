//
//  CSXboxController.m
//  Engine
//
//  Created by Aurora on 25/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import "CSXboxController.h"

@implementation CSXboxController

- (NSString *) name {
  return @"Xbox Wireless Controller";
}

- (void) rawAxis: (NSInteger)axis withState: (float)state {
  if (axis == 57) {
    switch ((int)state) {
      case 0:
        [self updateButton: CS_BUTTON_LEFT withState: false];
        [self updateButton: CS_BUTTON_RIGHT withState: false];
        [self updateButton: CS_BUTTON_UP withState: true];
        [self updateButton: CS_BUTTON_DOWN withState: false];
        break;
      case 45:
        [self updateButton: CS_BUTTON_LEFT withState: false];
        [self updateButton: CS_BUTTON_RIGHT withState: true];
        [self updateButton: CS_BUTTON_UP withState: true];
        [self updateButton: CS_BUTTON_DOWN withState: false];
        break;
      case 90:
        [self updateButton: CS_BUTTON_LEFT withState: false];
        [self updateButton: CS_BUTTON_RIGHT withState: true];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: false];
        break;
      case 135:
        [self updateButton: CS_BUTTON_LEFT withState: false];
        [self updateButton: CS_BUTTON_RIGHT withState: true];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: true];
        break;
      case 180:
        [self updateButton: CS_BUTTON_LEFT withState: false];
        [self updateButton: CS_BUTTON_RIGHT withState: false];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: true];
        break;
      case 225:
        [self updateButton: CS_BUTTON_LEFT withState: true];
        [self updateButton: CS_BUTTON_RIGHT withState: false];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: true];
        break;
      case 270:
        [self updateButton: CS_BUTTON_LEFT withState: true];
        [self updateButton: CS_BUTTON_RIGHT withState: false];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: false];
        break;
      case 315:
        [self updateButton: CS_BUTTON_LEFT withState: true];
        [self updateButton: CS_BUTTON_RIGHT withState: false];
        [self updateButton: CS_BUTTON_UP withState: true];
        [self updateButton: CS_BUTTON_DOWN withState: false];
        break;
      case -45:
        [self updateButton: CS_BUTTON_LEFT withState: false];
        [self updateButton: CS_BUTTON_RIGHT withState: false];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: false];
        break;
      default:
        NSLog(@"Unknown state: %f", state);
    }
  }
}

- (void) rawButton: (NSInteger)button withState: (NSInteger)state {
  bool value = state != 0;

  switch (button) {
    case 1: return [self updateButton: CS_BUTTON_B withState: value];
    case 2: return [self updateButton: CS_BUTTON_A withState: value];
    case 3: return [self updateButton: CS_BUTTON_Y withState: value];
    case 4: return [self updateButton: CS_BUTTON_X withState: value];
    case 5: return [self updateButton: CS_BUTTON_L withState: value];
    case 6: return [self updateButton: CS_BUTTON_R withState: value];
    case 7: return [self updateButton: CS_BUTTON_SELECT withState: value];
    case 8: return [self updateButton: CS_BUTTON_START withState: value];
    default:
      NSLog(@"Ignoring %ld", button);
      return;
  }
}

@end
