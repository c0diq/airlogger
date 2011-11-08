/*****************************************************************
|
|   AirLogger - BrowserViewController.h
|
| Created by Sylvain Rebaud on 9/6/11.
| Copyright (c) 2006-2011, MOG, Inc.
| All rights reserved.
|
| Redistribution and use in source and binary forms, with or without
| modification, are permitted provided that the following conditions are met:
|     * Redistributions of source code must retain the above copyright
|       notice, this list of conditions and the following disclaimer.
|     * Redistributions in binary form must reproduce the above copyright
|       notice, this list of conditions and the following disclaimer in the
|       documentation and/or other materials provided with the distribution.
|     * Neither the name of MOG nor the
|       names of its contributors may be used to endorse or promote products
|       derived from this software without specific prior written permission.
|
| THIS SOFTWARE IS PROVIDED BY MOG ''AS IS'' AND ANY
| EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
| WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
| DISCLAIMED. IN NO EVENT SHALL MOG BE LIABLE FOR ANY
| DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
| (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
| LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
| ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
| (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
| SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
|
****************************************************************/

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
