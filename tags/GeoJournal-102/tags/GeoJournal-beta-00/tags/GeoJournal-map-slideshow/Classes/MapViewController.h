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

@class ItineraryMark;

@interface MapViewController : UIViewController <MKMapViewDelegate> {
	IBOutlet MKMapView		*_mapView;
	IBOutlet UIView			*_slideSubView;
	IBOutlet UISlider		*_slider;
	IBOutlet UIView			*_settingView;
	IBOutlet UIView			*_mapParentView;
	IBOutlet UISegmentedControl		*_mapType;
	IBOutlet UISegmentedControl		*_categoryType;
	IBOutlet UISegmentedControl		*_numLocation;
	
	UIImage					*prevButton, *nextButton, *pauseButton, *stopButton;
	NSMutableArray			*categoryArray;
	NSInteger				numberOfItinerary;
	CLLocationDegrees		avgLatitude;
	CLLocationDegrees		avgLongitude;
	UIButton				*detailDisclosureButtonType;
	NSMutableArray			*markArray;
	NSMutableArray			*markInViewArray;
	NSInteger				markIndex;
	MKCoordinateRegion		centerRegion;
	BOOL					didAlertViewShown;
	BOOL					sliderBeingUsed;
	NSTimer					*slideShowTimer;
	NSInteger				currentCategoryType;
	NSInteger				currentNumLocation;
}

@property (nonatomic, retain) UISegmentedControl	*_mapType;
@property (nonatomic, retain) UISegmentedControl	*_categoryType;
@property (nonatomic, retain) UISegmentedControl	*_numLocation;
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

- (void)addToMap;
- (void)startSlideshow;
- (void)pauseSlideShow:(id)sender;
- (void)stopSlideShow:(id)sender;
- (void)continueSlideShow:(id)sender;
- (void)mapSettingDone:(id)sender;
- (IBAction)segmentAction:(id)sender;
- (IBAction)sliderTouchEnd:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;
- (IBAction)goSetting:(id)sender;
- (UIButton *)getDetailDisclosureButtonType:(ItineraryMark*)mark;

@end
