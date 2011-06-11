//
//  JournalEntryViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/13/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
	
@class Journal;
@class JournalViewController;

@interface JournalEntryViewController : UIViewController <AVAudioPlayerDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate> {
	IBOutlet UILabel			*titleForJournal;
	IBOutlet UIImageView		*imageForJournal;
	IBOutlet UIButton			*audioButton;
	IBOutlet UISlider			*audioSlider;
	IBOutlet UILabel			*textForJournal;
	IBOutlet UIScrollView		*scrollView;
	IBOutlet UILabel			*currentTime;
	IBOutlet UILabel			*duration;
	IBOutlet UIView				*containerView;
	IBOutlet UILabel			*audioLabel;
	IBOutlet UILabel			*creationDateLabel;
	IBOutlet UILabel			*locationLabel;
	IBOutlet UIBarButtonItem	*prevButton;
	IBOutlet UIBarButtonItem	*nextButton;
	IBOutlet UIBarButtonItem	*trashButton;
	IBOutlet UIToolbar			*toolbar;
	
	UIImage						*playButton;
	UIImage						*pauseButton;
	Journal						*entryForThisView;
	AVAudioPlayer				*_player;
	
	NSTimer						*_updateTimer;
	NSTimer						*_rewTimer;
	NSTimer						*_ffwTimer;
	NSMutableArray				*_soundFiles;	
	NSString					*_fbCall;
	
	JournalViewController		*_parent;
	NSInteger					indexForThis;
	BOOL						showToolbar;
}

@property (nonatomic, retain) UILabel					*creationDateLabel;
@property (nonatomic, retain) UILabel					*locationLabel;
@property (nonatomic, retain) UIImage					*playButton;
@property (nonatomic, retain) UIImage					*pauseButton;
@property (nonatomic, retain) UILabel					*audioLabel;
@property (nonatomic, retain) UIView					*containerView;
@property (nonatomic, retain) AVAudioPlayer				*_player;
@property (nonatomic, retain) UIScrollView				*scrollView;
@property (nonatomic, retain) UILabel					*titleForJournal;
@property (nonatomic, retain) UIImageView				*imageForJournal;
@property (nonatomic, retain) UIButton					*audioButton;
@property (nonatomic, retain) UISlider					*audioSlider;
@property (nonatomic, retain) UILabel					*textForJournal;
@property (nonatomic, retain) Journal					*entryForThisView;
@property (nonatomic, retain) UILabel					*currentTime;
@property (nonatomic, retain) UILabel					*duration;
@property (nonatomic, retain) NSTimer					*_updateTimer;
@property (nonatomic, retain) NSString					*_fbCall;
@property (nonatomic, retain) JournalViewController		*_parent;
@property (nonatomic, retain) UIBarButtonItem			*prevButton;
@property (nonatomic, retain) UIBarButtonItem			*nextButton;
@property (nonatomic, retain) UIBarButtonItem			*trashButton;
@property (nonatomic, retain) UIToolbar					*toolbar;

@property (nonatomic) BOOL								showToolbar;
@property (nonatomic) NSInteger							indexForThis;

- (IBAction)playButtonPressed:(UIButton*)sender;
- (IBAction)progressSliderMoved:(UISlider *)sender;
- (IBAction)goPrev:(id)sender;
- (IBAction)goNext:(id)sender;
- (IBAction)removeEntry:(id)sender;

- (void)updateCurrentTimeForPlayer:(AVAudioPlayer *)player;
- (void)updateCurrentTime;
- (void)updateViewForPlayerState:(AVAudioPlayer *)player;
- (void)updateViewForPlayerInfo:(AVAudioPlayer*)player;
- (void)pausePlaybackForPlayer:(AVAudioPlayer*)player;
- (void)startPlaybackForPlayer:(AVAudioPlayer*)player;
- (void)initializeAudio;
- (void)setToPlay;
- (void)setToPause;
- (void)sync;
- (void)syncWithMail;
- (void)syncWithFacebook;
- (void)showButtons;
- (void)reloadView;

@end
