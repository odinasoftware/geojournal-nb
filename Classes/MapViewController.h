//
//  MapViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/20/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MapViewCommonController.h"

@interface MapViewController : MapViewCommonController {
	IBOutlet UIView					*_slideSubView;
	IBOutlet UISlider				*_slider;
	IBOutlet UIView					*_settingView;
	IBOutlet UIView					*_mapParentView;
	IBOutlet UIButton				*_infoButton;
	IBOutlet UISegmentedControl		*_mapType;
	
	UIImage					*prevButton, *nextButton, *pauseButton, *stopButton;

	UIButton				*detailDisclosureButtonType;

	BOOL					didAlertViewShown;
	BOOL					sliderBeingUsed;
	NSTimer					*slideShowTimer;
	
	@private
	UIBarButtonItem			*_slideshowButton;
    
}

@property (nonatomic, retain) UIButton				*_infoButton;
@property (nonatomic, retain) UISegmentedControl	*_mapType;
@property (nonatomic, retain) UIView			*_mapParentView;
@property (nonatomic, retain) UIView			*_settingView;

@property (nonatomic, retain) UIImage			*prevButton;
@property (nonatomic, retain) UIImage			*nextButton;
@property (nonatomic, retain) UIImage			*pauseButton;
@property (nonatomic, retain) UIImage			*stopButton;
@property (nonatomic, readonly) UIButton		*detailDisclosureButtonType;

@property (nonatomic, retain) UIView			*_slideSubView;
@property (nonatomic, retain) UISlider			*_slider;
@property (nonatomic, retain) NSTimer			*slideShowTimer;
@property (nonatomic, retain) UIBarButtonItem	*_slideshowButton;



- (void)startSlideshow;
- (void)pauseSlideShow:(id)sender;
- (void)stopSlideShow:(id)sender;
- (void)continueSlideShow:(id)sender;
- (void)mapSettingDone:(id)sender;
- (IBAction)segmentAction:(id)sender;
- (IBAction)sliderTouchEnd:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;
- (IBAction)goSetting:(id)sender;
- (void)enableSegmentControlsFrom:(NSInteger)i ToIndex:(NSInteger)n;
- (ItineraryMark*)getMarkFromJournal:(Journal*)j;
- (UIButton *)getDetailDisclosureButtonType:(ItineraryMark*)mark fromAnnotationView:(MKAnnotationView*)annView;

- (void)adjustOrientation:(CGRect)bounds;

@end
