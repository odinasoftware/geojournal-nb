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
#import "GeoDefaults.h"

#define MAX_CALLOUT_TITLE_LEN		20
#define MAX_CALLOUT_CONTENT_LEN		20

#define GET_SAFE_SUBSTRING(x, len)	\
	([x length] < len ? x : [x substringToIndex:len])

@implementation ItineraryMark

@synthesize coordinate;
@synthesize isCenter;
@synthesize journalForLocation;
@synthesize active;
@synthesize parentController;
@synthesize indexForJournal;

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
		//title = GET_SAFE_SUBSTRING(self.journalForLocation.title, MAX_CALLOUT_TITLE_LEN);
		title = self.journalForLocation.title;
	}
	
	// To show annotiation view
	if (title == nil) {
		title = @"No Title";
	}
	
	return title;
}

- (NSString*)contentForLocation
{
	NSString *content = nil;
	if (self.journalForLocation) {
		//content = GET_SAFE_SUBSTRING(self.journalForLocation.text, MAX_CALLOUT_CONTENT_LEN);
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
		controller.showToolbar = NO;
		controller.entryForThisView = self.journalForLocation;
		controller.hidesBottomBarWhenPushed = YES;
		[GeoDefaults sharedGeoDefaultsInstance].thirdLevel = self.indexForJournal;
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
