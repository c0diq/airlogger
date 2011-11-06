//
//  AirLoggerAppDelegate.h
//  AirLogger
//
//  Created by Sylvain Rebaud on 9/6/11.
//  Copyright 2011 Plutinosoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BrowserViewController.h"
#import "Picker.h"

@interface AirLoggerAppDelegate : NSObject <UIApplicationDelegate, UIActionSheetDelegate, AVAudioPlayerDelegate,
                                            BrowserViewControllerDelegate,
                                            NSStreamDelegate> 
{
	UIWindow		*_window;
    AVAudioPlayer   *player;
	Picker			*_picker;
	NSOutputStream	*_outStream;
	BOOL			_outReady;
    BOOL            _broadcasting;
}

@end
