/*
     File: BrowserController.m
 Abstract: View controller for the service instance list.
 This object manages a NSNetServiceBrowser configured to look for Bonjour services.
 It has an array of NSNetService objects that are displayed in a table view.
 When the service browser reports that it has discovered a service, the corresponding NSNetService is added to the array.
 When a service goes away, the corresponding NSNetService is removed from the array.
 Selecting an item in the table view asynchronously resolves the corresponding net service.
 When that resolution completes, the delegate is called with the corresponding NSNetService.
  Version: 1.8
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "BrowserViewController.h"
#import "SynthesizeSingleton.h"

// A category on NSNetService that's used to sort NSNetService objects by their name.
@interface NSNetService (BrowserControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService *)aService;
@end

@implementation NSNetService (BrowserControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService *)aService {
	return [[self name] localizedCaseInsensitiveCompare:[aService name]];
}
@end


@interface BrowserController()
@property (nonatomic, retain, readwrite) NSMutableArray *services;
@property (nonatomic, retain, readwrite) NSMutableArray *resolvedServices;
@property (nonatomic, retain, readwrite) NSNetServiceBrowser *netServiceBrowser;

- (void)stopAllResolve;
@end

@implementation BrowserController

@synthesize delegate = _delegate;
@synthesize netServiceBrowser = _netServiceBrowser;
@synthesize services = _services;
@synthesize resolvedServices = _resolvedServices;

SYNTHESIZE_SINGLETON_FOR_CLASS(BrowserController);

- (id)init {
	
	if ((self = [super init])) {
		_services = [[NSMutableArray alloc] init];
		_resolvedServices = [[NSMutableArray alloc] init];
	}

	return self;
}

- (NSString *)searchingForServicesString {
	return _searchingForServicesString;
}

// Holds the string that's displayed in the table view during service discovery.
- (void)setSearchingForServicesString:(NSString *)searchingForServicesString {
	if (_searchingForServicesString != searchingForServicesString) {
		[_searchingForServicesString release];
		_searchingForServicesString = [searchingForServicesString copy];
	}
}

- (NSArray*) resolvedServices {
    return _resolvedServices;
}

// Creates an NSNetServiceBrowser that searches for services of a particular type in a particular domain.
// If a service is currently being resolved, stop resolving it and stop the service browser from
// discovering other services.
- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain {
	
	[self stopAllResolve];
	[self.netServiceBrowser stop];
	[self.services removeAllObjects];
	[self.resolvedServices removeAllObjects];

	NSNetServiceBrowser *aNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!aNetServiceBrowser) {
        // The NSNetServiceBrowser couldn't be allocated and initialized.
		return NO;
	}

	aNetServiceBrowser.delegate = self;
	self.netServiceBrowser = aNetServiceBrowser;
	[aNetServiceBrowser release];
	[self.netServiceBrowser searchForServicesOfType:type inDomain:domain];

	return YES;
}

- (void)stopAllResolve {

    [self.services enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(NSNetService*)obj stop];
    }];
}

- (void)resolve:(NSNetService *)service {
    
	[service setDelegate:self];

	// Attempt to resolve the service. A value of 0.0 sets an unlimited time to resolve it. The user can
	// choose to cancel the resolve by selecting another service in the table view.
	[service resolveWithTimeout:0.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
	// If a service went away, stop resolving it if it's currently being resolved,
	// remove it from the list and update the table view if no more events are queued.

    [service stop];
	[self.services removeObject:service];
}	

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
	
    // If a service came online, try to resolve right away
	[self.services addObject:service];
    [self resolve:service];
}	

// This should never be called, since we resolve with a timeout of 0.0, which means indefinite
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
	
    [sender stop];
    [self.services removeObject:sender];
}

- (void)netServiceDidResolveAddress:(NSNetService *)service {
	
	[service retain];
    [self.services removeObject:service];
    [self.resolvedServices addObject:service];
	[self.resolvedServices sortUsingSelector:@selector(localizedCaseInsensitiveCompareByName:)];
	
	[self.delegate browserController:self didResolveInstance:service];
	[service release];
}

- (void)dealloc {
	// Cleanup any running resolve and free memory
	[self stopAllResolve];
	self.services = nil;
    self.resolvedServices = nil;
	[self.netServiceBrowser stop];
	self.netServiceBrowser = nil;
	
	[super dealloc];
}

@end
