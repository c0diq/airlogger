//
//  BrowserViewController.h
//  AirLogger
//
//  Created by Sylvain Rebaud on 9/6/11.
//  Copyright 2011 Plutinosoft. All rights reserved.
//

/*
 Abstract: View controller for the service instance list.
 This object manages a NSNetServiceBrowser configured to look for Bonjour services.
 It has an array of NSNetService objects that are displayed in a table view.
 When the service browser reports that it has discovered a service, the corresponding NSNetService is automatically resovled. 
 When that resolution completes, the corresponding NSNetService is added to the array.
 When a service goes away, the corresponding NSNetService is removed from the array.
 When an an item is selected, the delegate is called with the corresponding resolved NSNetService.
*/

#import <UIKit/UIKit.h>
#import <Foundation/NSNetServices.h>

@class BrowserViewController;

@protocol BrowserViewControllerDelegate <NSObject>
@required
// This method will be invoked when the user selects one of the service instances from the list.
// The ref parameter will be the selected (already resolved) instance or nil if the user taps the 'Cancel' button (if shown).
- (void) browserViewController:(BrowserViewController *)bvc didSelectInstance:(NSNetService *)ref;
@end

@interface BrowserViewController : UITableViewController <NSNetServiceDelegate, NSNetServiceBrowserDelegate> {

@private
	id<BrowserViewControllerDelegate> _delegate;
	NSString *_searchingForServicesString;
	BOOL _showDisclosureIndicators;
	NSMutableArray *_services;
	NSMutableArray *_resolvedServices;
	NSNetServiceBrowser *_netServiceBrowser;
    NSNetService *_selectedService;
	NSTimer *_timer;
	BOOL _needsActivityIndicator;
	BOOL _initialWaitOver;
}

@property (nonatomic, assign) id<BrowserViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *searchingForServicesString;

- (id)initWithTitle:(NSString *)title showDisclosureIndicators:(BOOL)showDisclosureIndicators showCancelButton:(BOOL)showCancelButton;
- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain;
- (void)removeSelection;
@end
