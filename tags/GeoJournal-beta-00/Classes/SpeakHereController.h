/*
 
    File: SpeakHereController.h
Abstract: Class for handling user interaction and file record/playback
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

#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>

#import "AQLevelMeter.h"

#import "AQPlayer.h"
#import "AQRecorder.h"

typedef enum {GEO_RECORDER_NOOP, GEO_RECORDER_REC, GEO_RECORDER_PLAY, GEO_RECORDER_PAUSE, GEO_PLAY_PAUSED, GEO_RECORDER_STOP} GeoRecorderStatus;
typedef enum {GEO_BUTTON_NON, GEO_BUTTON_REC, GEO_BUTTON_PLAY, GEO_BUTTON_PAUSE, GEO_BUTTON_STOP} GeoButtonType;

@interface AudioService : NSObject 
{
	BOOL	inputAvailable;
}

@property (nonatomic) BOOL inputAvailable;

+ (AudioService*)sharedAudioServiceInstance;

@end


@interface SpeakHereController : NSObject <UIAlertViewDelegate> {

	@public
	IBOutlet UILabel*			fileDescription;
	IBOutlet AQLevelMeter*		lvlMeter_in;
	
	//Buttons for audio
	IBOutlet UIButton			*recButton;
	IBOutlet UIButton			*playButton;
	IBOutlet UIButton			*stopButton;
	IBOutlet UIImageView		*popupWarningView;
	IBOutlet UILabel			*warningMessage;
	IBOutlet UILabel			*recordStatus;
	IBOutlet UILabel			*timeLabel;
	
	UIImage						*recUpImage;
	UIImage						*playUpImage;
	UIImage						*stopUpImage;

	AQPlayer*					player;
	AQRecorder*					recorder;
	BOOL						playbackWasInterrupted;
	NSString*					recordFilePath;	
	
	CFURLRef					soundFileURLRef;
	SystemSoundID				soundFileObject;
	GeoRecorderStatus			geoRecorderStatus;
	//NSCalendar				*calendar;
	NSTimer						*secondTimer;
	NSTimer						*labelTimer;
	int							curTextIndex;
	NSDate						*startTime;
	NSDateFormatter				*dateFormatter;
	double						elapsedTime;

}

@property (nonatomic, retain)	UILabel				*fileDescription;
@property (nonatomic, retain)	AQLevelMeter		*lvlMeter_in;

@property (readonly)			AQPlayer			*player;
@property (readonly)			AQRecorder			*recorder;
@property						BOOL				playbackWasInterrupted;
@property (nonatomic, retain)	UILabel				*recordStatus;

@property (nonatomic, retain)	UIImage				*recUpImage;
@property (nonatomic, retain)	UIImage				*playUpImage;
@property (nonatomic, retain)	UIImage				*stopUpImage;

@property (readwrite)			CFURLRef			soundFileURLRef;
@property (readonly)			SystemSoundID		soundFileObject;

@property (nonatomic, retain)	UIImageView			*popupWarningView;
@property (nonatomic, retain)	UILabel				*warningMessage;
@property (nonatomic, retain)	NSTimer				*secondTimer;
@property (nonatomic, retain)	NSTimer				*labelTimer;
@property (nonatomic, retain)	NSDate				*startTime;
@property (nonatomic, retain)	NSDateFormatter		*dateFormatter;
@property (nonatomic, retain)	UILabel				*timeLabel;
@property (nonatomic, retain)	NSString			*recordFilePath;

- (void)initialization;

// Buttons for audio
- (IBAction)togglePauseButton:(id)sender;
- (IBAction)toggleRecButton:(id)sender;
- (IBAction)togglePlayButton:(id)sender;
- (IBAction)toggleStopButton:(id)sender;

- (void)stopPlayQueue;
- (void)stopRecord;
- (void)popupWarning:(NSString*)message;
- (void)closePopup:(id)sender;
- (void)switch2Next:(GeoButtonType)next;
- (void)updateLabel:(id)sender;
- (void)stopTimer;
- (void)setStartTimer;
- (void)closeAudioPlayer;

@end
