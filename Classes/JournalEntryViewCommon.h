//
//  JournalEntryViewCommon.h
//  GeoJournal
//
//  Created by Jae Han on 1/17/12.
//  Copyright (c) 2012 Home. All rights reserved.
//
#import <UIKit/UIKit.h>

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "FacebookConnect.h"
#import "ImageFrameView.h"
#import "StatusViewController.h"
#import "GeoSplitTableController.h"

@class Journal;
@class EditText;
@class JournalViewController;
@class ImageArrayScrollController;

@interface JournalEntryViewCommon : UIViewController 
<UINavigationControllerDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate, 
MFMailComposeViewControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, 
OpenFullViewDelegate, SelectImageDelegate, SubstitutableDetailViewController> {
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
	IBOutlet UIBarButtonItem	*increaseFontButton;
	IBOutlet UIBarButtonItem	*decreaseFontButton;
	IBOutlet UIView				*imageArrayView;
	IBOutlet UIButton			*stretchButton;
	IBOutlet ImageFrameView		*imageFrameView;
	//IBOutlet ImageArrayScrollController	*imageScrollViewController;
	
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
	
@protected
	CGRect						_frameRect;
	CGRect						_imageRect;
	CGRect						_containerViewRect;
	CGRect						_creationDateLabelRect;
	CGRect						_locationLabelRect;
	CGRect						_textForJournalRect;
	CGRect						_stretchButtonRect;
	EditText					*editTextController;
	NSInteger					fontSize;
	UIImage						*zoomIn;
	UIImage						*zoomOut;
	UIImage						*stretchImage;
	UIButton					*imageZoomButton;
	UIImagePickerController		*_cameraController;
	NSInteger					_baseIndex;
	
	// When picture is added
	UIImage						*addedPicture;
	UIImage						*thumbPicture;
	sync_action_t				_sync_action;
}

@property (nonatomic, retain) UIButton					*imageZoomButton;
@property (nonatomic, retain) UIImage					*zoomIn;
@property (nonatomic, retain) UIImage					*zoomOut;
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
@property (nonatomic, retain) UIBarButtonItem			*increaseFontButton;
@property (nonatomic, retain) UIBarButtonItem			*decreaseFontButton;
@property (nonatomic, retain) UIToolbar					*toolbar;
@property (nonatomic, retain) EditText					*editTextController;
@property (nonatomic, retain) UIImagePickerController	*cameraController;
@property (nonatomic, retain) UIImage					*addedPicture;
@property (nonatomic, retain) UIImage					*thumbPicture;
@property (nonatomic, retain) UIImage					*stretchImage;
@property (nonatomic, retain) UIView					*imageArrayView;
@property (nonatomic, retain) UIButton					*stretchButton;
@property (nonatomic, retain) ImageFrameView			*imageFrameView;
//@property (nonatomic, retain) ImageArrayScrollController	*imageScrollViewController;

@property (nonatomic) BOOL								showToolbar;
@property (nonatomic) NSInteger							indexForThis;

- (IBAction)playButtonPressed:(UIButton*)sender;
- (IBAction)progressSliderMoved:(UISlider *)sender;
- (IBAction)goPrev:(id)sender;
- (IBAction)goNext:(id)sender;
- (IBAction)removeEntry:(id)sender;
- (IBAction)editText:(id)sender;
- (IBAction)increaseFont:(id)sender;
- (IBAction)decreaseFont:(id)sender;
- (IBAction)editImage:(id)sender;
- (IBAction)showFullImage:(id)sender;

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
- (void)zoomOut:(id)sender;
- (void)sendMailWithImage:(NSString*)image;

@end
