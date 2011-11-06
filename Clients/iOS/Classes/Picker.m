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

#import "Picker.h"

#define kOffset 5.0

@interface Picker ()
@property (nonatomic, retain, readwrite) BrowserViewController *bvc;
@end

@implementation Picker

@synthesize bvc = _bvc;

- (id)initWithFrame:(CGRect)frame type:(NSString*)type {
	if ((self = [super initWithFrame:frame])) {
		// add autorelease to the NSNetServiceBrowser to release the browser once the connection has been
		// established. An active browser can cause a delay in sending data.
		// <rdar://problem/7000938>
		self.bvc = [[[BrowserViewController alloc] initWithTitle:nil showDisclosureIndicators:NO showCancelButton:NO]autorelease];
		[self.bvc searchForServicesOfType:type inDomain:@"local"];
		
		self.opaque = YES;
		self.backgroundColor = [UIColor blackColor];
		
		UIImageView* img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg.png"]];
		[self addSubview:img];
		[img release];
		
		CGFloat runningY = kOffset;
		CGFloat width = self.bounds.size.width - 2 * kOffset;
		
		UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont boldSystemFontOfSize:15.0]];
		[label setTextColor:[UIColor whiteColor]];
		[label setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[label setShadowOffset:CGSizeMake(1,1)];
		[label setBackgroundColor:[UIColor clearColor]];
		label.text = @"Searching for AirLogger servers";
		label.numberOfLines = 1;
		[label sizeToFit];
		label.frame = CGRectMake(kOffset, runningY, width, label.frame.size.height);
		[self addSubview:label];
		
		runningY += label.bounds.size.height;
		[label release];
		
		//runningY += label.bounds.size.height + 2;
		
		[self.bvc.view setFrame:CGRectMake(0, runningY, self.bounds.size.width, self.bounds.size.height - runningY)];
		[self addSubview:self.bvc.view];
		
	}

	return self;
}

- (void)dealloc {
	// Cleanup any running resolve and free memory
	[self.bvc release];
	
	[super dealloc];
}

- (void)removeSelection {
    [self.bvc removeSelection];
}

- (id<BrowserViewControllerDelegate>)delegate {
	return self.bvc.delegate;
}

- (void)setDelegate:(id<BrowserViewControllerDelegate>)delegate {
	[self.bvc setDelegate:delegate];
}

@end
