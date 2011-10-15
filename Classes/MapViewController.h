//
//  MapViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/20/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import <MapKit/MKReverseGeocoder.h>

typedef enum {MAP_MARK_ASCENDING, MAP_MARK_DESCENDING} MAP_DIRECTION_TYPE;
	
@class ItineraryMark;
@class Journal;

@interface MapViewController : UIViewController <MKMapViewDelegate> {
	IBOutlet MKMapView				*_mapView;
	IBOutlet UIView					*_slideSubView;
	IBOutlet UISlider				*_slider;
	IBOutlet UIView					*_settingView;
	IBOutlet UIView					*_mapParentView;
	IBOutlet UIButton				*_infoButton;
	IBOutlet UISegmentedControl		*_mapType;
	
	UIImage					*prevButton, *nextButton, *pauseButton, *stopButton;
	NSMutableArray			*categoryArray;
	NSInteger				numberOfItinerary;
	CLLocationDegrees		avgLatitude;
	CLLocationDegrees		avgLongitude;
	UIButton				*detailDisclosureButtonType;
	NSMutableArray			*markArray;
	NSMutableArray			*markInViewArray;
	MKCoordinateRegion		centerRegion;
	BOOL					didAlertViewShown;
	BOOL					sliderBeingUsed;
	NSTimer					*slideShowTimer;
	NSInteger				currentCategoryType;
	Journal					*restoredJournal;
	
	@private
	NSString				*_category;
	NSInteger				_currentJournalIndex;
	UISegmentedControl		*_segmentControl;
	NSArray					*journalArray;
	NSEnumerator			*_enumerator;
	ItineraryMark			*_currentMark;
	NSInteger				markIndex;
	UIImageView				*_noLocationWarning;
	BOOL					_locationLoaded;
	UIBarButtonItem			*_slideshowButton;
	UIBarButtonItem			*_segmentControlButton;
	UILabel					*_titleLabel;
}

@property (nonatomic, retain) UIButton				*_infoButton;
@property (nonatomic, retain) UISegmentedControl	*_mapType;
@property (nonatomic, retain) UISegmentedControl	*_segmentControl;
@property (nonatomic, retain) UIView			*_mapParentView;
@property (nonatomic, retain) UIView			*_settingView;
@property (nonatomic, retain) MKMapView			*_mapView;
@property (nonatomic, retain) NSMutableArray	*categoryArray;
@property (nonatomic, retain) UIImage			*prevButton;
@property (nonatomic, retain) UIImage			*nextButton;
@property (nonatomic, retain) UIImage			*pauseButton;
@property (nonatomic, retain) UIImage			*stopButton;
@property (nonatomic, readonly) UIButton		*detailDisclosureButtonType;
@property (nonatomic, retain) NSMutableArray	*markArray;
@property (nonatomic, retain) NSMutableArray	*markInViewArray;
@property (nonatomic, retain) UIView			*_slideSubView;
@property (nonatomic, retain) UISlider			*_slider;
@property (nonatomic, retain) NSTimer			*slideShowTimer;
@property (nonatomic, retain) Journal			*restoredJournal;
@property (nonatomic, retain) NSString			*_category;
@property (nonatomic, retain) NSArray			*journalArray;
@property (nonatomic, retain) ItineraryMark		*_currentMark;
@property (nonatomic, retain) NSEnumerator		*_enumerator;
@property (nonatomic, retain) UIImageView		*_noLocationWarning;
@property (nonatomic, retain) UIBarButtonItem	*_slideshowButton;
@property (nonatomic, retain) UIBarButtonItem	*_segmentControlButton;
@property (nonatomic, retain) UILabel			*_titleLabel;

- (void)resetMarks;
- (void)startSlideshow;
- (void)restoreLevel;
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
- (void)addToMapWithDirection:(MAP_DIRECTION_TYPE)direction upto:(NSInteger)size;
- (void)adjustOrientation:(CGRect)bounds;

@end
