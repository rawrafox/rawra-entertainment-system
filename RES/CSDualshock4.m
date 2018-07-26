//
//  CSDualshock4.m
//  Engine
//
//  Created by Aurora on 25/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import "CSDualshock4.h"

@implementation CSDualshock4

- (NSString *) name {
  return @"Dualshock 4";
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
      case 1:
        [self updateButton: CS_BUTTON_LEFT withState: false];
        [self updateButton: CS_BUTTON_RIGHT withState: true];
        [self updateButton: CS_BUTTON_UP withState: true];
        [self updateButton: CS_BUTTON_DOWN withState: false];
        break;
      case 2:
        [self updateButton: CS_BUTTON_LEFT withState: false];
        [self updateButton: CS_BUTTON_RIGHT withState: true];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: false];
        break;
      case 3:
        [self updateButton: CS_BUTTON_LEFT withState: false];
        [self updateButton: CS_BUTTON_RIGHT withState: true];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: true];
        break;
      case 4:
        [self updateButton: CS_BUTTON_LEFT withState: false];
        [self updateButton: CS_BUTTON_RIGHT withState: false];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: true];
        break;
      case 5:
        [self updateButton: CS_BUTTON_LEFT withState: true];
        [self updateButton: CS_BUTTON_RIGHT withState: false];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: true];
        break;
      case 6:
        [self updateButton: CS_BUTTON_LEFT withState: true];
        [self updateButton: CS_BUTTON_RIGHT withState: false];
        [self updateButton: CS_BUTTON_UP withState: false];
        [self updateButton: CS_BUTTON_DOWN withState: false];
        break;
      case 7:
        [self updateButton: CS_BUTTON_LEFT withState: true];
        [self updateButton: CS_BUTTON_RIGHT withState: false];
        [self updateButton: CS_BUTTON_UP withState: true];
        [self updateButton: CS_BUTTON_DOWN withState: false];
        break;
      case 8:
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
    case 1: return [self updateButton: CS_BUTTON_Y withState: value];
    case 2: return [self updateButton: CS_BUTTON_B withState: value];
    case 3: return [self updateButton: CS_BUTTON_A withState: value];
    case 4: return [self updateButton: CS_BUTTON_X withState: value];
    case 5: return [self updateButton: CS_BUTTON_L withState: value];
    case 6: return [self updateButton: CS_BUTTON_R withState: value];
    case 7: return [self updateButton: CS_BUTTON_L withState: value];
    case 8: return [self updateButton: CS_BUTTON_R withState: value];
    case 9: return [self updateButton: CS_BUTTON_SELECT withState: value];
    case 10: return [self updateButton: CS_BUTTON_START withState: value];
    case 13: return [self updateButton: CS_BUTTON_START withState: value];
    default:
      NSLog(@"Ignoring %ld", button);
      return;
  }
}

@end
