/*****************************************************************
|
|   AirLogger - AirLoggerAppDelegate.m
|
| Created by Sylvain Rebaud on 9/6/11.
| Copyright (c) 2006-2011, Plutinosoft, LLC.
| All rights reserved.
|
| Redistribution and use in source and binary forms, with or without
| modification, are permitted provided that the following conditions are met:
|     * Redistributions of source code must retain the above copyright
|       notice, this list of conditions and the following disclaimer.
|     * Redistributions in binary form must reproduce the above copyright
|       notice, this list of conditions and the following disclaimer in the
|       documentation and/or other materials provided with the distribution.
|     * Neither the name of Plutinosoft nor the
|       names of its contributors may be used to endorse or promote products
|       derived from this software without specific prior written permission.
|
| THIS SOFTWARE IS PROVIDED BY PLUTINOSOFT ''AS IS'' AND ANY
| EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
| WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
| DISCLAIMED. IN NO EVENT SHALL PLUTINOSOFT BE LIABLE FOR ANY
| DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
| (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
| LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
| ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
| (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
| SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
|
****************************************************************/

#import "AirLoggerAppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import <asl.h>

@interface AirLoggerAppDelegate ()
- (void) setup:(BOOL)clearSelection;
@end

@implementation AirLoggerAppDelegate

- (void)_showAlert:(NSString *)title
{
    // TODO: Use a local notification instead since we're in the background most likely when this happens
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (void)setupAudioSession {
    // initialize the audio session o   bject for this application,
    // registering the callback that Audio Session Services will invoke 
    // it when there's an interruption
    AudioSessionInitialize(NULL,
                           NULL,
                           NULL,
                           NULL);
    
    // before instantiating the player object, 
    // set the audio session category to prevent audio
    // from stopping when going to sleep
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                            sizeof(sessionCategory),
                            &sessionCategory);
    
    UInt32 allowMixing = true;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers,
                            sizeof(allowMixing),
                            &allowMixing);
    
    // setup background audio player to play silence to keep WiFi up when in background or asleep
    NSURL *fileURL = [[[NSURL alloc] initFileURLWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"sound.caf"]] autorelease];
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil]; 
    player.delegate = self;
}

- (void)startSilencePlayback {
    // create a player that will play silence in a loop to force WiFi to stay on
    // even when phone goes to sleep!   
    AudioSessionSetActive(YES);
    player.numberOfLoops = -1; // infinite looping
    [player play];
}

- (void)stopSilencePlayback {
    [player stop];
    AudioSessionSetActive(NO);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{        
    // setup silence playback so we can stay in the background on iOS4
    [self setupAudioSession];
    [self startSilencePlayback];
    
	// create a full-screen window
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[_window setBackgroundColor:[UIColor darkGrayColor]];
    
    _picker = [[Picker alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] type:@"_airlogger._tcp"];
    _picker.delegate = self;
    [_window addSubview:_picker];
    
    // show the window
	[_window makeKeyAndVisible];

    return YES;
}

- (void)dealloc
{
	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_outStream release];
	
    [player release];
	[_picker release];
	[_window release];
	
	[super dealloc];
}

- (void)setup:(BOOL)clearSelection 
{
    // if we were running, reload table
    if (clearSelection) [_picker removeSelection];
    
	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream release];
	_outStream = nil;
	_outReady = NO;
}

// If we display an error or an alert that the remote disconnected, handle dismissal and return to setup
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self setup:YES];
}

- (void)openStreams
{
	_outStream.delegate = self;
	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream open];
}

- (void) connect:(NSNetService*)service {
    [self setup:NO];
    
    // in case we're still broadcasting (background thread), wait unil it's done
    // by retrying in a bit
    if (_broadcasting) {
        [self performSelector:@selector(connect:) withObject:service afterDelay:0.3f];
        return;
    }
    
	// note the following method returns _inStream and _outStream with a retain count that the caller must eventually release
	if (![service getInputStream:nil outputStream:&_outStream]) {
		[self _showAlert:@"Failed connecting to server"];
		return;
	}
    
	[self openStreams];
}

- (void)browserViewController:(BrowserViewController *)bvc didSelectInstance:(NSNetService *)netService
{
	[self connect:netService];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [self stopSilencePlayback];
}

- (NSArray*)fetchLog:(NSMutableDictionary*)oldEntries sender:(NSString*)sender{
    aslmsg q, m;
    int i;
    const char *key, *val;
    BOOL foundNewEntry = NO;
    int index = -1;
    
    NSMutableArray* logs = [NSMutableArray arrayWithCapacity:200];
    
    q = asl_new(ASL_TYPE_QUERY);
    if (sender) {
        asl_set_query(q, ASL_KEY_SENDER, "mog", ASL_QUERY_OP_EQUAL); // I think it's a sql equivalent to like %s%
    }
    
    aslresponse r = asl_search(NULL, q);
    while (NULL != (m = aslresponse_next(r)))
    {
        ++index;
        
        NSMutableDictionary *logEntry = [NSMutableDictionary dictionaryWithCapacity:6];
        
        BOOL skip = NO;
        for (i = 0; (NULL != (key = asl_key(m, i))); i++)
        {
            NSString *keyString = [NSString stringWithUTF8String:(char *)key];
            val = asl_get(m, key);
            NSString *string = [NSString stringWithUTF8String:val];
            
            // look for entry in last result set since query could return
            // prior results, if so, skip
            if (!foundNewEntry && 
                [keyString compare:@"ASLMessageID"] == NSOrderedSame &&
                [oldEntries objectForKey:string]) {
                skip = YES;
                break;
            }
            
            [logEntry setObject:string forKey:keyString];
        }
        // found entry, go to next
        if (skip) continue;
        
        // empty old result set now that we have detected a new entry
        if (!foundNewEntry) {
            foundNewEntry = YES;
            
            // remove old entries if first item returned is not in our list
            if (index == 0) [oldEntries removeAllObjects];
        }
        
        //NSLog(@"%@", logEntry);
        
        // key dictionary of new entries so we can look up fast
        // next time if we got an old entry back from query
        NSString* keyString = [logEntry objectForKey:@"ASLMessageID"];
        [oldEntries setObject:logEntry forKey:keyString];
        
        // add new entry
        [logs addObject:logEntry];
    }
    aslresponse_free(r);
    return logs;
}

- (void)sendMessage:(NSString*)message withFacility:(NSString*)facility {
    if (!message) return;
    
    if (_outStream && _outReady) {
        // create a fanout message using the facility as the channel so clients can filter on it
        NSString* fanout = [NSString stringWithFormat:@"announce %@ %@\n", facility, message];
        NSData* data = [fanout dataUsingEncoding:NSUTF8StringEncoding];
        
        NSUInteger written = 0;
        while (data.length != written) {
            written = [_outStream write:(const uint8_t *)data.bytes+written
                              maxLength:data.length-written];
            // bail out on failure
            if (written == -1) {
                _outReady = NO;
                return;
            }
        }
    }
}

- (void)sendMessages:(NSArray*)logEntries {
    for (NSDictionary* logEntry in logEntries) {
        [self sendMessage:[logEntry objectForKey:@"Message"] 
               withFacility:[logEntry objectForKey:@"Facility"]];
    }
}

- (void)broadcastLog {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableDictionary* _oldEntries = [NSMutableDictionary dictionary];
    
    while (1) {   
        // get new log entries and keep around in _oldEntries what we've seen so far
        NSArray* logEntries = [self fetchLog:_oldEntries sender:nil];
        [self sendMessages:logEntries];
        
        // if aborted, bail out now
        if (!_outReady) 
            break;
        usleep(300000);
    }
    
    _broadcasting = NO;
    [pool release];
}

@end

#pragma mark AVAudioPlayerDelegate
@implementation AirLoggerAppDelegate (AVAudioPlayerDelegate)

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    [self stopSilencePlayback];
}

/* audioPlayerEndInterruption:withFlags: is called when the audio session interruption has ended and this player had been interrupted while playing. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags {
    [self startSilencePlayback];
}

@end

#pragma mark -
@implementation AirLoggerAppDelegate (NSStreamDelegate)

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	UIAlertView *alertView;
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{
			_outReady = YES;
            _broadcasting = YES;
            [self performSelectorInBackground:@selector(broadcastLog) withObject:nil];
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			//NSLog(@"%s", _cmd);
			[self _showAlert:@"Error encountered on stream!"];			
			break;
		}
			
		case NSStreamEventEndEncountered:
		{
            // TODO: Use a local notification instead since we're in the background most likely when this happens
			alertView = [[UIAlertView alloc] initWithTitle:@"Server Disconnected!" 
                                                   message:nil 
                                                  delegate:self 
                                         cancelButtonTitle:nil 
                                         otherButtonTitles:@"Continue", nil];
			[alertView show];
			[alertView release];
            
			break;
		}
	}
}

@end
