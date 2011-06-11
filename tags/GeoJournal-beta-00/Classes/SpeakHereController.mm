//
/*

    File: SpeakHereController.mm
Abstract: n/a
 Version: 2.0

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

Copyright (C) 2009 Apple Inc. All Rights Reserved.


*/

#import "SpeakHereController.h"
#import "GeoJournalHeaders.h"
#import "CommonObject.h"
#import "GeoDefaults.h"
#import "GeoDatabase.h"

#define INITIAL_AUDIO_BANNER	" Please press Record button to begin recording!"
#define MAX_LABEL_LEN			40

void interruptionListener(	void *	inClientData,
						  UInt32	inInterruptionState);
void propListener(	void *                  inClientData,
				  AudioSessionPropertyID	inID,
				  UInt32                  inDataSize,
				  const void *            inData);

static AudioService *sharedAudioService = nil;

@implementation AudioService

@synthesize inputAvailable;


+ (AudioService*)sharedAudioServiceInstance
{
	//@synchronized (self) {
	if (sharedAudioService == nil) {
		[[self alloc] init];
	}
	//}
	return sharedAudioService;
}
	
+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedAudioService == nil) { 
			sharedAudioService = [super allocWithZone:zone]; 
			return sharedAudioService; // assignment and return on first allocation 
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

	
-(id)init 
{
	self = [super init];
	if (self) {
		OSStatus error = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
		if (error) printf("ERROR INITIALIZING AUDIO SESSION! %d\n", error);
		else 
		{										
			error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self);
			if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %d\n", error);
			UInt32 binputAvailable = 0;
			UInt32 size = sizeof(binputAvailable);
			
			// we do not want to allow recording if input is not available
			error = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &binputAvailable);
			if (error) printf("ERROR GETTING INPUT AVAILABILITY! %d\n", error);
			self.inputAvailable = (binputAvailable) ? YES : NO;
			
			// we also need to listen to see if input availability changes
			error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, propListener, self);
			if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %d\n", error);
		}
		
		
	}
	return self;
}		

#pragma mark AudioSession listeners
void interruptionListener(	void *	inClientData,
						  UInt32	inInterruptionState)
{
	SpeakHereController *THIS = (SpeakHereController*)inClientData;
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{
		TRACE("%s: begin interrupt.\n", __func__);
		if (THIS->recorder->IsRunning()) {
			[THIS stopRecord];
		}
		else if (THIS->player->IsRunning()) {
			//the queue will stop itself on an interruption, we just need to update the AI
			[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueStopped" object:THIS];
			THIS->playbackWasInterrupted = YES;
		}
	}
	else if ((inInterruptionState == kAudioSessionEndInterruption) && THIS->playbackWasInterrupted)
	{
		TRACE("%s: end interrupt\n", __func__);
		printf("Resuming queue\n");
		// we were playing back when we were interrupted, so reset and resume now
		THIS->player->StartQueue(true);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:THIS];
		THIS->playbackWasInterrupted = NO;
	}
}

/*
 the Simulator does not simulate session behavior. There is no way to invoke an interruption in the simulator, 
 to change the setting of the Ring/Silent switch, to simulate screen lock, to simulate an audio hardware route 
 change, or to test audio mixing behavior—playing your audio along with audio from a background application. 
 To test the behavior of your audio session code, you need to run on a device. 

 
 A well-written iPhone application activates and deactivates its audio session according to its audio activity. 
 In a recording and playback application, for instance, you would activate your session just before you start 
 recording or playback, and deactivate it just after you stop. Prompt deactivation of your audio session is part 
 of being a good iPhone OS citizen. It allows background applications—typically the iPod—to resume playback.
 
 */
void propListener(	void *                  inClientData,
				  AudioSessionPropertyID	inID,
				  UInt32                  inDataSize,
				  const void *            inData)
{
	SpeakHereController *THIS = (SpeakHereController*)inClientData;
	TRACE("%s, %d\n", __func__, inID);
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		TRACE("%s, kAudioSessionProperty_AudioRouteChange.\n", __func__);
		CFDictionaryRef routeDictionary = (CFDictionaryRef)inData;			
		//CFShow(routeDictionary);
		CFNumberRef reason = (CFNumberRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
		SInt32 reasonVal;
		CFNumberGetValue(reason, kCFNumberSInt32Type, &reasonVal);
		if (reasonVal != kAudioSessionRouteChangeReason_CategoryChange)
		{
			/*CFStringRef oldRoute = (CFStringRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_OldRoute));
			 if (oldRoute)	
			 {
			 printf("old route:\n");
			 CFShow(oldRoute);
			 }
			 else 
			 printf("ERROR GETTING OLD AUDIO ROUTE!\n");
			 
			 CFStringRef newRoute;
			 UInt32 size; size = sizeof(CFStringRef);
			 OSStatus error = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);
			 if (error) printf("ERROR GETTING NEW AUDIO ROUTE! %d\n", error);
			 else
			 {
			 printf("new route:\n");
			 CFShow(newRoute);
			 }*/
			
			if (reasonVal == kAudioSessionRouteChangeReason_OldDeviceUnavailable)
			{			
				if (THIS->player->IsRunning()) {
					[THIS stopPlayQueue];
				}		
			}
			
			// stop the queue if we had a non-policy route change
			if (THIS->recorder->IsRunning()) {
				[THIS stopRecord];
			}
		}	
	}
	else if (inID == kAudioSessionProperty_AudioInputAvailable)
	{
		TRACE("%s, kAudioSessionProperty_AudioInputAvailable", __func__);
		if (inDataSize == sizeof(UInt32)) {
			//UInt32 isAvailable = *(UInt32*)inData;
			// disable recording if input is not available
		}
	}
}


@end


@implementation SpeakHereController

@synthesize player;
@synthesize recorder;

@synthesize fileDescription;
@synthesize lvlMeter_in;
@synthesize playbackWasInterrupted;

@synthesize recUpImage, playUpImage, stopUpImage;
@synthesize soundFileURLRef, soundFileObject;
@synthesize secondTimer, labelTimer;
@synthesize popupWarningView, warningMessage;
@synthesize recordStatus;
@synthesize startTime;
@synthesize dateFormatter;
@synthesize timeLabel;
@synthesize recordFilePath;

char *OSTypeToStr(char *buf, OSType t)
{
	char *p = buf;
	char str[4], *q = str;
	*(UInt32 *)str = CFSwapInt32(t);
	for (int i = 0; i < 4; ++i) {
		if (isprint(*q) && *q != '\\')
			*p++ = *q++;
		else {
			sprintf(p, "\\x%02x", *q++);
			p += 4;
		}
	}
	*p = '\0';
	return buf;
}

-(void)setFileDescriptionForFormat: (CAStreamBasicDescription)format withName:(NSString*)name
{
	char buf[5];
	const char *dataFormat = OSTypeToStr(buf, format.mFormatID);
	NSString* description = [[NSString alloc] initWithFormat:@"(%d ch. %s @ %g Hz)", format.NumberChannels(), dataFormat, format.mSampleRate, nil];
	fileDescription.text = description;
	[description release];	
}

#pragma mark Playback routines

-(void)stopPlayQueue
{
	TRACE("%s\n", __func__);
	player->StopQueue();
	[lvlMeter_in setAq: nil];
}

- (void)stopRecord
{
	
	
	if (recorder->IsRunning()) {
		TRACE("%s, :%d\n", __func__, recorder->IsRunning());	
		// Disconnect our level meter from the audio queue
		[lvlMeter_in setAq: nil];
		
		recorder->StopRecord();
		
		// dispose the previous playback queue
		player->DisposeQueue(true);
		
		// now create a new queue for the recorded file
		//recordFilePath = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilename];//(CFStringRef)[NSTemporaryDirectory() stringByAppendingPathComponent: @"recordedFile.caf"];
		if (recordFilePath == nil) {
			NSLog(@"%s, file has not been created.", __func__);
			return;
		}
		player->CreateQueueForFile((CFStringRef)recordFilePath);
		
		// Set the button's state back to "record"
		//btn_record.title = @"Record";
	
	}
}

- (void)showWarningLabel:(NSString*)message
{
	[self.labelTimer invalidate];
	self.labelTimer = nil;
	self.recordStatus.text = message;
}

- (void)playRecord
{
	if (player->IsRunning()) {
		NSLog(@"%s, recording is playing.", __func__);
	}
	else {
				
		[self setStartTimer];
		OSStatus result = player->StartQueue(false);
		if (result == noErr)
			[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
	}
}

- (void)startRecording
{
	if (recorder->IsRunning()) {
		NSLog(@"%s, recorder is running.", __func__);
	}
	else {
		[self setStartTimer];
		// setting record file path.
		self.recordFilePath = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:GEO_AUDIO_EXT];
		
		TRACE("%s, file: %s\n", __func__, [recordFilePath UTF8String]);
		recorder->StartRecord((CFStringRef)recordFilePath);//recorder->StartRecord(CFSTR("recordedFile.caf"));
		
		//[self setFileDescriptionForFormat:recorder->DataFormat() withName:@"Recorded File"];
		
		// Hook the level meter up to the Audio Queue for the recorder
		[lvlMeter_in setAq: recorder->Queue()];
	}
}

- (void) setStartTimer
{
	if (startTime) {
		[startTime release];
	}
	curTextIndex = 0;
	elapsedTime = 0.0;
	startTime = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:0.0];
	
}

- (void)pauseRecord
{
	recorder->PauseRecord();
}

- (void)pausePlay
{
	player->Pause();
}

- (void)restartRecoding
{
	// TODO: how to resume recording
	recorder->ResumeRecord();
}

- (void)replayRecord
{
	int error = 0;
	
	// TODO: how to resume playing.
	if ((error = player->ResumeQueue()) < 0) {
		NSLog(@"%s, error. %d", error);
	}
}
				
#pragma mark Initialization routines
- (id)init 
{
	if (self = [super init]) {
		[self initialization];
	}
	
	return self;
}
- (void)initialization
{		
	TRACE_HERE;
	// Allocate our singleton instance for the recorder & player object
	geoRecorderStatus = GEO_RECORDER_NOOP;
	
	recorder = new AQRecorder();
	player = new AQPlayer();
		
	// Initialize audio session using signleton class
	[AudioService sharedAudioServiceInstance];
	
	

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackQueueStopped:) name:@"playbackQueueStopped" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackQueueResumed:) name:@"playbackQueueResumed" object:nil];

	//UIColor *bgColor = [[UIColor alloc] initWithRed:.39 green:.44 blue:.57 alpha:.5];
	UIColor *bgColor = [[UIColor alloc] initWithRed:.843 green:.859 blue:.769 alpha:.5];
	[lvlMeter_in setBackgroundColor:bgColor];
	[lvlMeter_in setBorderColor:bgColor];
	[bgColor release];
	
	self.recUpImage = [UIImage imageNamed:@"rec-up.png"];
	//recDownImage = [UIImage imageNamed:@"rec-down.png"];
	self.playUpImage = [UIImage imageNamed:@"play-up.png"];
	//playDownImage = [UIImage imageNamed:@"play-down.png"];
	self.stopUpImage = [UIImage imageNamed:@"stop-up.png"];
	//stopDownImage = [UIImage imageNamed:@"stop-down.png"];
	
	// Initialize audio file
	CFBundleRef mainBundle;
	mainBundle = CFBundleGetMainBundle ();
	
	// Get the URL to the sound file to play
	soundFileURLRef  =	CFBundleCopyResourceURL (
												 mainBundle,
												 CFSTR ("click"),
												 CFSTR ("aif"),
												 NULL
												 );
	
	// Create a system sound object representing the sound file
	AudioServicesCreateSystemSoundID (
									  soundFileURLRef,
									  &soundFileObject
									  );
	
	
	// disable the play button since we have no recording to play yet

	playbackWasInterrupted = NO;
	
	// Start timer for displaying banner.
	curTextIndex = 0;
	elapsedTime = 0.0;
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"mm:ss"];
	self.labelTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateLabel:) userInfo:nil repeats:YES];
	//calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];//[CommonObject sharedCommonObjectInstance].calendar;
}

- (void)closeAudioPlayer
{
	if (player) {
		delete player;
		player = NULL;
	}
	if (recorder) {
		delete recorder;
		recorder = NULL;
	}
		
}

- (void)popupWarning:(NSString*)message
{
	/*
	NSDate *date = [NSDate date];
	NSDate *twoSecondFromNow = [date addTimeInterval:10];
    
	NSCalendarUnit unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
	NSDateComponents *timerDateComponents = [calendar components:unitFlags fromDate:twoSecondFromNow];	
	NSDate *secondTimerDate = [calendar dateFromComponents:timerDateComponents];
	
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:secondTimerDate interval:2 target:self selector:@selector(closePopup:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	self.secondTimer = timer;
	[timer release];
	 */
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(closePopup:) userInfo:nil repeats:NO];
	self.secondTimer = timer;
	
	popupWarningView.hidden = NO;
	warningMessage.hidden = NO;
	warningMessage.text = message;
}

- (void)closePopup:(id)sender
{
	warningMessage.hidden = YES;
	popupWarningView.hidden = YES;
	[self.secondTimer invalidate];
	self.secondTimer = nil;
}

/* updateLabel:
 * TODO: When play is stopped, this label update should know that too. 
 */
- (void)updateLabel:(id)sender
{
	NSMutableData *text = nil;
	NSMutableString *displayText = nil;
	NSDate *tmp = nil;
	NSString *displayTime = nil;
	char *textPtr = (char*)INITIAL_AUDIO_BANNER;
	char *displayPtr = textPtr;
	int len = strlen(textPtr);
	int n = 0;
	
	//TRACE("%s\n", __func__);
	switch (geoRecorderStatus) {
		case GEO_RECORDER_NOOP:
			displayPtr += curTextIndex;
			
			text = [[NSMutableData alloc] initWithBytes:displayPtr length:len-curTextIndex];
			if (curTextIndex > 0) {
				[text appendBytes:textPtr length:curTextIndex];
			}
			curTextIndex = (curTextIndex + 1) % len;
			
			displayText = [[NSString alloc] initWithData:text encoding:NSUTF8StringEncoding];
			self.recordStatus.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12];
			self.recordStatus.text = displayText;
			[displayText release];
			[text release];
			break;
		case GEO_RECORDER_REC:
			tmp = [startTime addTimeInterval:++elapsedTime];
			displayTime = [dateFormatter stringFromDate:tmp];
			
			n = curTextIndex++ % 3;
			//TRACE("%s, update record time: %p\n", __func__, startTime);
			
			displayText = [[NSMutableString alloc] initWithString:@"Recording "];
			for (int i=0; i<n+1; ++i) {
				[displayText appendFormat:@". "];
			}
			
			self.recordStatus.text = displayText;
			self.recordStatus.textColor = [UIColor redColor];
			[displayText release];
			self.timeLabel.text = displayTime;
			self.timeLabel.textColor = [UIColor redColor];
			break;
		case GEO_RECORDER_PLAY:
			if (player->IsRunning()) {
				tmp = [startTime addTimeInterval:++elapsedTime];
				displayTime = [dateFormatter stringFromDate:tmp];
				
				n = curTextIndex++ % 3;
				//TRACE("%s, update record time: %p\n", __func__, startTime);
				
				displayText = [[NSMutableString alloc] initWithString:@"Playing "];
				for (int i=0; i<n+1; ++i) {
					[displayText appendFormat:@". "];
				}
				
				self.recordStatus.text = displayText;
				self.recordStatus.textColor = [UIColor blackColor];
				[displayText release];
				self.timeLabel.text = displayTime;
				self.timeLabel.textColor = [UIColor blackColor];
			}
			else {
				geoRecorderStatus = GEO_RECORDER_STOP;
			}
			break;
		case GEO_RECORDER_PAUSE:
		case GEO_PLAY_PAUSED:
			self.recordStatus.text = @"Paused.";
			self.recordStatus.textColor = [UIColor blackColor];
			self.timeLabel.text = nil;
			break;
		case GEO_RECORDER_STOP:
			self.recordStatus.text = @"Stopped.";
			self.recordStatus.textColor = [UIColor blackColor];
			self.timeLabel.text = nil;
			break;
		default:
			NSLog(@"%s, unknown behaviour. %d", __func__, geoRecorderStatus);
	}
	
}

- (void)stopTimer
{
	[self.labelTimer invalidate];
	self.labelTimer = nil;
}

# pragma mark Notification routines
- (void)playbackQueueStopped:(NSNotification *)note
{
	//btn_play.title = @"Play";
	[lvlMeter_in setAq: nil];

}

- (void)playbackQueueResumed:(NSNotification *)note
{
	//btn_play.title = @"Stop";

	[lvlMeter_in setAq: player->Queue()];
}

- (IBAction)toggleRecButton:(id)sender
{
	TRACE("%s\n", __func__);
	//AudioServicesPlaySystemSound (self.soundFileObject);
	[self switch2Next:GEO_BUTTON_REC];
}

- (IBAction)togglePauseButton:(id)sender
{
	TRACE("%s\n", __func__);
	//AudioServicesPlaySystemSound (self.soundFileObject);
	[self switch2Next:GEO_BUTTON_PAUSE];
}

- (IBAction)togglePlayButton:(id)sender
{
	TRACE("%s\n", __func__);
	//AudioServicesPlaySystemSound (self.soundFileObject);
	[self switch2Next:GEO_BUTTON_PLAY];
}

- (IBAction)toggleStopButton:(id)sender
{
	TRACE("%s\n", __func__);
	//AudioServicesPlaySystemSound (self.soundFileObject);
	[self switch2Next:GEO_BUTTON_STOP];
}

- (void)switch2Next:(GeoButtonType)next 
{
	UIAlertView *alert = nil;
	
	switch (geoRecorderStatus) {
		case GEO_RECORDER_NOOP:
			switch (next) {
				case GEO_BUTTON_REC:
					[self popupWarning:GORECORDING_STARTED];
					[self startRecording];
					geoRecorderStatus = GEO_RECORDER_REC;
					break;
				case GEO_BUTTON_PLAY:
					[self popupWarning:GORECORDING_NOTHING_TO_PLAY];
					break;
				case GEO_BUTTON_PAUSE:
					[self popupWarning:GORECORDING_NOTHING_TO_PAUSE];
					break;
				case GEO_BUTTON_STOP:
					[self popupWarning:GORECORDING_NOTHING_TO_STOP];
					break;
				default:
					NSLog(@"%s, unknown status: %d, %d", __func__, geoRecorderStatus, next);
			}
			break;
		case GEO_RECORDER_REC:
			switch (next) {
				case GEO_BUTTON_REC:
					[self popupWarning:GORECORDING_STARTED_ALREADY];
					break;
				case GEO_BUTTON_PLAY:
					// Stop recorder and play
					//[self popupWarning:GORECORDING_STOPPED];
					[self stopRecord];
					[self popupWarning:GOAUDIO_PLAY_STARTED];
					[self playRecord];
					geoRecorderStatus = GEO_RECORDER_PLAY;
					break;
				case GEO_BUTTON_PAUSE:
					[self pauseRecord];
					// Pause
					geoRecorderStatus = GEO_RECORDER_PAUSE;
					[self popupWarning:GORECORDING_PASUED];
					break;
				case GEO_BUTTON_STOP:
					[self stopRecord];
					geoRecorderStatus = GEO_RECORDER_STOP;
					[self popupWarning:GORECORDING_STOPPED];
					break;
				default:
					NSLog(@"%s, unknown status: %d, %d", __func__, geoRecorderStatus, next);
			}
			break;
		case GEO_RECORDER_PLAY:
			switch (next) {
				case GEO_BUTTON_REC:
					// need to pop up warning.
					// open a alert with an OK and cancel button
					alert = [[UIAlertView alloc] initWithTitle:@"Audio Warning" message:@"Previously recorded audio will be erased." 
													  delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
					[alert show];
					[alert release];
					break;
				case GEO_BUTTON_PLAY:
					if (player->IsRunning()) {
						[self popupWarning:GOAUDIO_PLAY_STARTED_ALREADY];
					}
					else {
						[self playRecord];
						[self popupWarning:GOAUDIO_PLAY_STARTED];
					}
					break;
				case GEO_BUTTON_PAUSE:
					[self pausePlay];
					geoRecorderStatus = GEO_PLAY_PAUSED;
					[self popupWarning:GOAUDIO_PLAY_PASUED];
					// Pause
					break;
				case GEO_BUTTON_STOP:
					[self stopPlayQueue];
					geoRecorderStatus = GEO_RECORDER_STOP;
					[self popupWarning:GOAUDIO_PLAY_STOPPED];
					break;
				default:
					NSLog(@"%s, unknown status: %d, %d", __func__, geoRecorderStatus, next);
			}
			break;
		case GEO_RECORDER_PAUSE:
			switch (next) {
				case GEO_BUTTON_REC:
					[self restartRecoding];
					geoRecorderStatus = GEO_RECORDER_REC;
					[self popupWarning:GORECORDING_RESUMED];
					break;
				case GEO_BUTTON_PLAY:
					//[self popupWarning:GORECORDING_STOPPED];
					[self stopRecord];
					[self popupWarning:GOAUDIO_PLAY_STARTED];
					[self playRecord];
					geoRecorderStatus = GEO_RECORDER_PLAY;
					break;
				case GEO_BUTTON_PAUSE:
					[self popupWarning:GOAUDIO_PLAY_PAUSED_ALREADY];
					// Pause
					break;
				case GEO_BUTTON_STOP:
					[self stopRecord];
					geoRecorderStatus = GEO_RECORDER_STOP;
					[self popupWarning:GORECORDING_STOPPED];
					break;
				default:
					NSLog(@"%s, unknown status: %d, %d", __func__, geoRecorderStatus, next);
			}
			break;
		case GEO_PLAY_PAUSED:
			switch (next) {
				case GEO_BUTTON_REC:
					[self restartRecoding];
					geoRecorderStatus = GEO_RECORDER_REC;
					[self popupWarning:GOAUDIO_PLAY_RESUMED];
					break;
				case GEO_BUTTON_PLAY:
					[self replayRecord];
					geoRecorderStatus = GEO_RECORDER_PLAY;
					break;
				case GEO_BUTTON_PAUSE:
					[self popupWarning:GOAUDIO_PLAY_PAUSED_ALREADY];
					// Pause
					break;
				case GEO_BUTTON_STOP:
					[self stopRecord];
					geoRecorderStatus = GEO_RECORDER_STOP;
					[self popupWarning:GOAUDIO_PLAY_STOPPED];
					break;
				default:
					NSLog(@"%s, unknown status: %d, %d", __func__, geoRecorderStatus, next);
			}			
			break;
		case GEO_RECORDER_STOP:
			switch (next) {
				case GEO_BUTTON_REC:
					alert = [[UIAlertView alloc] initWithTitle:@"Audio Warning" message:@"Previously recorded audio will be erased."
																   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
					[alert show];
					[alert release];
					break;
				case GEO_BUTTON_PLAY:
					[self playRecord];
					geoRecorderStatus = GEO_RECORDER_PLAY;
					[self popupWarning:GOAUDIO_PLAY_STARTED];
					break;
				case GEO_BUTTON_PAUSE:
					[self popupWarning:GORECORDING_STOPPED_ALREADY];
					// Pause
					break;
				case GEO_BUTTON_STOP:
					[self popupWarning:GORECORDING_STOPPED_ALREADY];
					break;
				default:
					NSLog(@"%s, unknown status: %d, %d", __func__, geoRecorderStatus, next);
			}
			
			break;
		default:
			NSLog(@"%s, unknown status: %d", __func__, geoRecorderStatus);
	}
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// use "buttonIndex" to decide your action
	//
	if (buttonIndex == 1) {
		// want to erase audio.
		[self startRecording];
		geoRecorderStatus = GEO_RECORDER_REC;
		[self popupWarning:GORECORDING_STARTED];
	}
	
}

#pragma mark Cleanup
- (void)dealloc
{
	TRACE_HERE;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[fileDescription release];
	[lvlMeter_in release];
	
	[recButton release];
	[playButton release];
	[stopButton release];
	
	[recUpImage release]; //[recDownImage release];
	[playUpImage release]; //[playDownImage release];
	[stopUpImage release]; //[stopDownImage release];
	
	[secondTimer release];
	[startTime release];
	[dateFormatter release];
	[recordFilePath release];
	
	if (player) 
		delete player;
	if (recorder)
		delete recorder;
	
	AudioServicesDisposeSystemSoundID (self.soundFileObject);
	CFRelease (soundFileURLRef);

	[super dealloc];
}

@end
