//
//  Picker.h
//  AirLogger
//
//  Created by Sylvain Rebaud on 9/6/11.
//  Copyright 2011 Plutinosoft. All rights reserved.
//

/*
 Abstract: A view that displays a list of AirLogger Servers
 available on the local network - discovered & displayed by BrowserViewController.
*/

#import <UIKit/UIKit.h>
#import "BrowserViewController.h"

@interface Picker : UIView {

@private
	BrowserViewController *_bvc;
}

@property (nonatomic, assign) id<BrowserViewControllerDelegate> delegate;

- (id)initWithFrame:(CGRect)frame type:(NSString *)type;
- (void)removeSelection;

@end
