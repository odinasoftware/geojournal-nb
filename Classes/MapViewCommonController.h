//
//  MapViewCommonController.h
//  GeoJournal
//
//  Created by Jae Han on 12/22/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import <MapKit/MKReverseGeocoder.h>

#import "GeoDatabase.h"
#import "GeoDefaults.h"
#import "ItineraryMark.h"
#import "GCategory.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "JournalEntryViewController.h"

typedef enum {MAP_MARK_ASCENDING, MAP_MARK_DESCENDING} MAP_DIRECTION_TYPE;

extern NSString *getThumbnailFilename(NSString *filename);
extern NSString *getThumbnailOldFilename(NSString *filename);
extern Boolean testReachability();

#define kViewTag					1
#define kThumbImageViewTag			2

#define DEFAULT_ITINERARY_NUMBER	10
#define kCustomButtonHeight			30.0

#define MIN_SLIDER_VALUE			1.0
#define MAX_SLIDER_VALUE			10.0
#define INITIAL_SLIDE_WAITING_TIME	2.0
#define DEFAULT_SLIDER_VALUE		3.0
#define DEFAULT_MAP_SPAN			0.05

#define WARNING_Y					130

#define kConnectObjectKey			@"object"
#define kConnectHeaderKey			@"header"
#define kConnectFooterKey			@"footer"
#define kConnectRowsKey				@"rows"

#define MAP_TYPE_INDEX				0
#define CATEGORY_INDEX				1
#define NUM_LOCATION_INDEX			2

@class ItineraryMark;
@class Journal;


@interface MapViewCommonController : UIViewController <MKMapViewDelegate> {
    IBOutlet UIBarButtonItem		*_segmentControlButton;
    IBOutlet UISegmentedControl		*_segmentControl;
    IBOutlet MKMapView				*_mapView;
    
   	NSMutableArray			*categoryArray;
    
    @protected
    NSInteger				numberOfItinerary;
	CLLocationDegrees		avgLatitude;
	CLLocationDegrees		avgLongitude;
    
    NSMutableArray			*markArray;
	NSMutableArray			*markInViewArray;
   	NSString				*_category;
    NSInteger               _numberOfPins;
    NSInteger				_currentJournalIndex;
    BOOL					_locationLoaded;
    UILabel					*_titleLabel;
    NSArray					*journalArray;
    MKCoordinateRegion		centerRegion;
    NSInteger				currentCategoryType;
	Journal					*restoredJournal;
    NSEnumerator			*_enumerator;
	ItineraryMark			*_currentMark;
	NSInteger				markIndex;
    UIImageView				*_noLocationWarning;

}

@property (nonatomic, retain) NSMutableArray	*categoryArray;
@property (nonatomic, retain) NSMutableArray	*markArray;
@property (nonatomic, retain) NSMutableArray	*markInViewArray;
@property (nonatomic, retain) NSString			*_category;
@property (nonatomic, retain) UILabel			*_titleLabel;
@property (nonatomic, retain) NSArray			*journalArray;
@property (nonatomic, retain) Journal			*restoredJournal;
@property (nonatomic, retain) ItineraryMark		*_currentMark;
@property (nonatomic, retain) NSEnumerator		*_enumerator;
@property (nonatomic, retain) UIImageView		*_noLocationWarning;
@property (nonatomic, retain) MKMapView			*_mapView;
@property (nonatomic, retain) UISegmentedControl    *_segmentControl;
@property (nonatomic, retain) UIBarButtonItem       *_segmentControlButton;


- (void)resetMarks;
- (void)restoreLevel;
- (GCategory*)getViewCategory;
- (void)addToMapWithDirection:(MAP_DIRECTION_TYPE)direction upto:(NSInteger)size;

@end
