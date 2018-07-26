//
//  CSGamepadSubsystem.m
//  Engine
//
//  Created by Aurora on 25/07/2018.
//  Copyright © 2018 Aventine. All rights reserved.
//

#import "CSGamepadSubsystem.h"
#import "CSGamepad.h"
#import "CSDualshock4.h"
#import "CSXboxController.h"

#import <IOKit/hid/IOHIDLib.h>

static void gamepadInput(void *context, IOReturn result, void *sender, IOHIDValueRef value) {
  if (result != kIOReturnSuccess) {
    return;
  }

  CSGamepad * gamepad = (__bridge CSGamepad *)context;

  IOHIDElementRef element = IOHIDValueGetElement(value);

  uint32_t usagePage = IOHIDElementGetUsagePage(element);
  uint32_t usage = IOHIDElementGetUsage(element);

  if (usagePage == kHIDPage_Button) {
    CFIndex state = IOHIDValueGetIntegerValue(value);

    [gamepad rawButton: usage withState: state];
  } else if (usagePage == kHIDPage_GenericDesktop) {
    float state = IOHIDValueGetScaledValue(value, kIOHIDValueScaleTypeCalibrated);

    [gamepad rawAxis: usage withState: state];
  }
}

static void gamepadDisconnected(void *context, IOReturn result, void *sender) {
  CSGamepad * gamepad = (__bridge_transfer CSGamepad *)context;

  [gamepad disconnect];
}

static void gamepadConnected(void * context, IOReturn result, void * sender, IOHIDDeviceRef device) {
  if (result == kIOReturnSuccess) {
    CSGamepadSubsystem * gamepadSubsystem = (__bridge CSGamepadSubsystem *)context;

    CSGamepad * gamepad;

    NSUInteger vid = [(__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey)) unsignedIntegerValue];
    NSUInteger pid = [(__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey)) unsignedIntegerValue];

    if (vid == 0x045E && pid == 0x02E0) {
      gamepad = [[CSXboxController alloc] initWithSubsystem: gamepadSubsystem];
    } else if (vid == 0x054C && (pid == 0x05C4 || pid == 0x9CC)) {
      gamepad = [[CSDualshock4 alloc] initWithSubsystem: gamepadSubsystem];
    } else {
      NSLog(@"Unknown Controller Connected 0x%lx, 0x%lx: Ignoring due to missing mapping", vid, pid);
      return;
    }

    IOHIDDeviceRegisterInputValueCallback(device, gamepadInput, (__bridge void *)gamepad);

    NSArray * criteria = @[
      @{@(kIOHIDElementUsagePageKey): @(kHIDPage_GenericDesktop)},
      @{@(kIOHIDElementUsagePageKey): @(kHIDPage_Button)},
    ];

    IOHIDDeviceSetInputValueMatchingMultiple(device, (__bridge CFArrayRef)criteria);
    IOHIDDeviceRegisterRemovalCallback(device, gamepadDisconnected, (__bridge_retained void *)gamepad);
  }
}

@implementation CSGamepadSubsystem {
  IOHIDManagerRef hidManager;
  CSGamepadConfiguration configuration;
  CSGamepadState gamepadState[CS_MAX_GAMEPADS];
  NSMutableDictionary<NSNumber *, CSGamepad *> * gamepads;
}

- (instancetype) init {
  if (self = [super init]) {
    hidManager = IOHIDManagerCreate(kCFAllocatorDefault, 0);

    gamepads = [NSMutableDictionary dictionaryWithCapacity: 4];

    NSArray * criteria = @[
      @{@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop), @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_Joystick)},
      @{@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop), @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_GamePad)},
      @{@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop), @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_MultiAxisController)},
    ];

    IOHIDManagerSetDeviceMatchingMultiple(hidManager, (__bridge CFArrayRef)criteria);
    // IOHIDManagerSetDeviceMatching(hidManager, nil);

    if (IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone) != kIOReturnSuccess) {
      NSLog(@"Error initializing gamepad subsystem");

      return nil;
    }

    IOHIDManagerRegisterDeviceMatchingCallback(hidManager, gamepadConnected, (__bridge void *)self);

    IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
  }

  return self;
}

 - (CSGamepadConfiguration *) gamepadConfiguration {
   return &configuration;
 }

- (CSGamepadState *) gamepads {
  return &gamepadState[0];
}

- (void) strobe {
  CSGamepadConfiguration cfg = { .gamepads = 0 };

  for (int i = 0; i < CS_MAX_GAMEPADS; i++) {
    CSGamepad * gamepad = [gamepads objectForKey: [NSNumber numberWithInt: i]];

    if (gamepad) {
      cfg.gamepads |= (1 << i);
      gamepadState[i] = [gamepad snapshot];
    }
  }
}

- (void) addGamepad: (CSGamepad *) gamepad {
  for (int i = 0; i < CS_MAX_GAMEPADS; i++) {
    NSNumber * key = [NSNumber numberWithInt: i];

    if (![gamepads objectForKey: key]) {
      [gamepads setObject: gamepad forKey: key];
      NSLog(@"Added Gamepad %@ (%i), %@", gamepad.name, i, gamepads);
      return;
    }
  }

  NSLog(@"Skipped Gamepad %@ since all ports are full, %@", gamepad.name, gamepads);
}

- (void) removeGamepad: (CSGamepad *) gamepad {
  for (int i = 0; i < CS_MAX_GAMEPADS; i++) {
    NSNumber * key = [NSNumber numberWithInt: i];

    if ([gamepads objectForKey: key] == gamepad) {
      [gamepads removeObjectForKey: key];
      NSLog(@"Removed Gamepad %@ (%i), %@", gamepad.name, i, gamepads);
      return;
    }
  }

  NSLog(@"Skipped disconnecting gamepad %@ since not connected, %@", gamepad.name, gamepads);
}
@end
