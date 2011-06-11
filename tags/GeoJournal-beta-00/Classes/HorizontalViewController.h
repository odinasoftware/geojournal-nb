//
//  HorizontalViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/30/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@class HorizontalImageViewController;
@class Journal;

@interface HorizontalPageViewControllerPointer : NSObject
{
	HorizontalImageViewController	*controller;
	NSInteger						page;
}

@property (nonatomic, assign) NSInteger page;
@property (nonatomic, retain) HorizontalImageViewController *controller;

- (id)initWithPage:(NSInteger)num;

@end


@interface HorizontalViewController : UIViewController <UIScrollViewDelegate, AVAudioPlayerDelegate> {
	IBOutlet UIScrollView			*_scrollView;
	IBOutlet UIImageView			*_imageView;
	IBOutlet UISwitch				*_showSlideShow;
	IBOutlet UISwitch				*_enableAudio;
	IBOutlet UISwitch				*_showContent;
	IBOutlet UIView					*_settingView;
	IBOutlet UIView					*_audioButtonView;
	IBOutlet UIButton				*_audioButton;
	IBOutlet UIView					*_playButtonView;
	IBOutlet UIButton				*_playButton;
	IBOutlet UISlider				*_slider;
	IBOutlet UIView					*_contentView;
	IBOutlet UITextView				*articleDescription;
	IBOutlet UILabel				*articleTitle;

	NSArray							*controllerArray;
	NSMutableArray					*categoryArray;
	NSArray							*journalArray;
	NSInteger						numberOfPages;
	NSInteger						currentArrayPointer;
	NSInteger						currentPage;
	NSInteger						currentSelectedPage;
	BOOL							isSlideShowRunning;
	HorizontalImageViewController	*currentSlideImageController;
	
	BOOL							contentShown;
	BOOL							audioShown;
	BOOL							playShown;
	
	AVAudioPlayer					*_player;
	UIImage							*_audioStopButton;
	UIImage							*_bigPlayButton;
	UIImage							*_bigStopButton;
	UIImage							*_audioPlayButton;
	UIImage							*_audioNoAvailButton;
	NSTimer							*slideShowTimer;
	NSInteger						currentSlideshowPage;
	NSInteger						currentPlayedPage;
}

@property (nonatomic, retain) UITextView			*articleDescription;
@property (nonatomic, retain) UILabel				*articleTitle;
@property (nonatomic, retain) UIView				*_contentView;
@property (nonatomic, retain) UISlider				*_slider;
@property (nonatomic, retain) UIImage				*_audioPlayButton;
@property (nonatomic, retain) AVAudioPlayer			*_player;
@property (nonatomic, retain) UIImage				*_audioStopButton;
@property (nonatomic, retain) UIImage				*_bigPlayButton;
@property (nonatomic, retain) UIImage				*_bigStopButton;
@property (nonatomic, retain) UIImage				*_audioNoAvailButton;
@property (nonatomic, retain) UIView				*_audioButtonView;
@property (nonatomic, retain) UIView				*_playButtonView;
@property (nonatomic, retain) UIButton				*_audioButton;
@property (nonatomic, retain) UIButton				*_playButton;
@property (nonatomic, retain) UIView				*_settingView;
@property (nonatomic, retain) UISwitch				*_showSlideShow;
@property (nonatomic, retain) UISwitch				*_enableAudio;
@property (nonatomic, retain) UISwitch				*_showContent;

@property (nonatomic, retain) UIScrollView			*_scrollView;
@property (nonatomic, retain) UIImageView			*_imageView;
@property (nonatomic, retain) NSMutableArray		*categoryArray;
@property (nonatomic, retain) NSArray				*journalArray;
@property (nonatomic, retain) NSTimer				*slideShowTimer;
@property (nonatomic, retain) NSArray				*controllerArray;
@property (nonatomic, retain) HorizontalImageViewController *currentSlideImageController;

- (IBAction)goSetting:(id)sender;
- (IBAction)playAudio:(id)sender;
- (IBAction)playSlideshow:(id)sender;
- (void)stopSlideShow:(id)sender;

- (NSInteger)setPagesForSlideShow;
- (void)showNoImageWarning;
- (void)loadImageView:(NSInteger)page;
- (Journal*)getJournalForPage:(NSInteger)page;
- (UIButton*)getInfoButton;
- (void)showGadgets:(UIView*)view;
- (void)showContentOfIndex:(NSInteger)index;
- (void)showNextImage:(NSTimer*)timer;
- (HorizontalImageViewController*)getNextImageViewControllerWithPage:(NSInteger)page needRedraw:(BOOL*)redraw;
- (HorizontalImageViewController*)getImageControllerWithPage:(NSInteger)page;

@end
