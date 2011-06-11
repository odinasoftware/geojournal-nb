//
//  ParkPlaceMark.h
//  MapTest
//
//  Created by Jae Han on 5/6/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class Journal;

@interface ItineraryMark : NSObject<MKAnnotation> {
	CLLocationCoordinate2D	coordinate;
	BOOL					isCenter;
	
	Journal					*journalForLocation;
	BOOL					active;
	UIViewController		*parentController;
	NSInteger				indexForJournal;
}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) Journal *journalForLocation;
@property (nonatomic, readonly) NSString *imageForLocation;
@property (nonatomic, readonly) NSString *titleForLocation;
@property (nonatomic, readonly) NSString *contentForLocation;
@property (nonatomic) BOOL isCenter;
@property (nonatomic) BOOL active;
@property (nonatomic) NSInteger indexForJournal;
@property (nonatomic, retain) UIViewController *parentController;

- (id)initWithCoordinate:(CLLocationCoordinate2D)c;
- (id)initWithLongitude:(CLLocationDegrees)longitude withLatitude:(CLLocationDegrees)latitude;

- (NSString*)subtitle;
- (NSString*)title;
- (IBAction)selectLocation:(id)sender;

@end
