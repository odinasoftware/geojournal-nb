//
//  ParkPlaceMark.m
//  MapTest
//
//  Created by Jae Han on 5/6/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "ItineraryMark.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "JournalEntryViewController.h"

@implementation ItineraryMark
@synthesize coordinate;
@synthesize isCenter;
@synthesize journalForLocation;
@synthesize active;
@synthesize parentController;

- (NSString*)subtitle {
	return self.contentForLocation;
}

- (NSString*)title {
	NSLog(@"%s: %s", __func__, [self.titleForLocation UTF8String]);
	return self.titleForLocation;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)c {
	if (self = [super init]) {
		coordinate = c;
		isCenter = NO;
		active = NO;
	}
	return self;
}

- (id)initWithLongitude:(CLLocationDegrees)longitude withLatitude:(CLLocationDegrees)latitude
{
	if (self = [super init]) {
		coordinate.longitude = longitude;
		coordinate.latitude = latitude;
		isCenter = NO;
		active = NO;
	}
	
	return self;
}

- (NSString*)imageForLocation
{
	NSString *image = nil;
	if (self.journalForLocation) {
		image = self.journalForLocation.picture;
	}
	return image;
}

- (NSString*)titleForLocation
{
	NSString *title = nil;
	if (self.journalForLocation) {
		title = self.journalForLocation.title;
	}
	return title;
}

- (NSString*)contentForLocation
{
	NSString *content = nil;
	if (self.journalForLocation) {
		content = self.journalForLocation.text;
	}
	return content;
}
	
#pragma mark USER CONTROL ACTIONS

- (IBAction)selectLocation:(id)sender
{
	// TODO: Implement view controller showing the content for this location.
	TRACE("%s, %s\n", __func__, [journalForLocation.title UTF8String]);
	if (parentController) {
		JournalEntryViewController *controller = [[JournalEntryViewController alloc] initWithNibName:@"JournalEntryView" bundle:nil];
		controller.entryForThisView = self.journalForLocation;
		controller.hidesBottomBarWhenPushed = YES;
		[parentController.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}

#pragma mark -
- (void)dealloc
{
	[parentController release];
	[journalForLocation release];
	[super dealloc];
}
@end
