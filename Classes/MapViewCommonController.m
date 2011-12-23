//
//  MapViewCommonController.m
//  GeoJournal
//
//  Created by Jae Han on 12/22/11.
//  Copyright (c) 2011 Home. All rights reserved.
//
#import <SystemConfiguration/SystemConfiguration.h>

#import "MapViewCommonController.h"

@implementation MapViewCommonController

@synthesize markArray;
@synthesize markInViewArray;
@synthesize _category;
@synthesize categoryArray;
@synthesize _titleLabel;
@synthesize journalArray;
@synthesize restoredJournal;
@synthesize _currentMark;
@synthesize _enumerator;
@synthesize _segmentControl;
@synthesize _segmentControlButton;
@synthesize _noLocationWarning;
@synthesize _mapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.markArray = [[NSMutableArray alloc] initWithCapacity:DEFAULT_ITINERARY_NUMBER];
	self.markInViewArray = [[NSMutableArray alloc] initWithCapacity:DEFAULT_ITINERARY_NUMBER];
	
    self._category = nil;
	self.categoryArray = [GeoDatabase sharedGeoDatabaseInstance].categoryArray;

    if (testReachability() == false) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Map Warning" message:@"Internet connection is not available. Your map may not be available. Please check your Internet connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	TRACE("%s, %d\n", __func__, self.interfaceOrientation);

}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if ([GeoDefaults sharedGeoDefaultsInstance].levelRestored == NO) {
		[self restoreLevel];
	}
	else {
		if (self._category == nil) {
			// View loaded first.
			[self addToMapWithDirection:MAP_MARK_ASCENDING upto:_numberOfPins];
			self._category = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
		} else if ([[GeoDefaults sharedGeoDefaultsInstance] needRefreshCategory:self._category]) {
			// Need to reload
			_locationLoaded = NO;
			_currentJournalIndex = 0;
			[self resetMarks];
			[self addToMapWithDirection:MAP_MARK_ASCENDING upto:_numberOfPins];
			self._category = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
			self._titleLabel.text = self._category;
		} else {
			// see if the number of journal has been changed or not.
			NSArray *array = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:[self getViewCategory]];
			if ([array count] != [self.journalArray count]) {
				[self resetMarks];
				[self addToMapWithDirection:MAP_MARK_ASCENDING upto:_numberOfPins];
			}
		}
		
		[GeoDefaults sharedGeoDefaultsInstance].thirdLevel = -1;
	}
}

- (void)restoreLevel
{
	int index = [GeoDefaults sharedGeoDefaultsInstance].secondLevel;
	int index2 = [GeoDefaults sharedGeoDefaultsInstance].thirdLevel;
	
	if (index > -1) {
		_currentJournalIndex = index;
		[self addToMapWithDirection:MAP_MARK_ASCENDING upto:_numberOfPins];
	}
	
	if (index2 == -1) {
		// only when there was no third level.
		self._category = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
	}
	
	if (index2 > -1 && self.restoredJournal) {
		TRACE("%s\n", __func__);
		JournalEntryViewController *controller = [[JournalEntryViewController alloc] initWithNibName:@"JournalEntryView" bundle:nil];
		controller.entryForThisView = self.restoredJournal;
		controller.hidesBottomBarWhenPushed = YES;
		[self.navigationController pushViewController:controller animated:NO];
		[controller release];
		self.restoredJournal = nil;
	}
	[GeoDefaults sharedGeoDefaultsInstance].levelRestored = YES;
}

- (GCategory*)getCategoryFromString:(NSString*)string 
{
	GCategory *c = nil;
	/*
     if ([string compare:NO_ACTIVE_CATEGORY] == NSOrderedSame) {
     c = [categoryArray objectAtIndex:0];
     }
     else {
	 */
    for (GCategory *t in self.categoryArray) {
        if ([t.name compare:string] == NSOrderedSame) {
            TRACE("%s, found category: %s\n", __func__, [string UTF8String]);
            c = t;
            break;
        }
    }
	//}	
	
	return c;
}

- (GCategory*)getViewCategory
{
	GCategory *c = nil;
	NSString *categoryString = nil;
	
	categoryString = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
	c = [self getCategoryFromString:categoryString];
    
	return c;
	
	return c;
}

- (ItineraryMark*)getMarkFromJournal:(Journal*)j
{
	ItineraryMark *mark = [[ItineraryMark alloc] initWithLongitude:[j.longitude doubleValue] withLatitude:[j.latitude doubleValue]];
	mark.journalForLocation = j;
	mark.active = YES;
	
	return mark;
}

- (void)enableSegmentControlsFrom:(NSInteger)i ToIndex:(NSInteger)n
{
	if (i+1 >= [journalArray count]) {
		[self._segmentControl setEnabled:NO forSegmentAtIndex:1];
	}
	else {
		[self._segmentControl setEnabled:YES forSegmentAtIndex:1];
	}
	
	if (_currentJournalIndex <=0) {
		[self._segmentControl setEnabled:NO forSegmentAtIndex:0];
	} 
	else {
		[self._segmentControl setEnabled:YES forSegmentAtIndex:0];
	}
	
	//if (i+n < [journalArray count] && _currentJournalIndex > 0) {
	//	[self._segmentControl setEnabled:YES forSegmentAtIndex:1];
	//	[self._segmentControl setEnabled:YES forSegmentAtIndex:0];
	//}
	TRACE("%s, ci: %d, i:%d, c: %d\n", __func__, _currentJournalIndex, i, [journalArray count]);
}

- (void)addToMapWithDirection:(MAP_DIRECTION_TYPE)direction upto:(NSInteger)size
{
	int n = 0;
	double latitude, longitude;
	CLLocationCoordinate2D centerCoordinate;
	CLLocationCoordinate2D coord;
	MKCoordinateSpan delta, current;
	
	Journal *j = nil;
	
	numberOfItinerary = -1; //getNumberOfLocation(self._numLocation.selectedSegmentIndex);
    
	avgLatitude = avgLongitude = 0.0;
	// Add location to map
	
	int i = 0;
	self.journalArray = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:[self getViewCategory]];
	//for (Journal *j in array) {
	TRACE("%s, current journal index: %d\n", __func__, _currentJournalIndex);
	
	for (i=_currentJournalIndex; i<[journalArray count]; ++i) {
		j = [journalArray objectAtIndex:i];
		if (j.address == nil) 
			continue;
		latitude = [j.latitude doubleValue];
		longitude = [j.longitude doubleValue];
		
		ItineraryMark *mark = [[ItineraryMark alloc] initWithLongitude:longitude withLatitude:latitude];
		avgLatitude += latitude; avgLongitude += longitude;
		
		if ([GeoDefaults sharedGeoDefaultsInstance].levelRestored == NO && [GeoDefaults sharedGeoDefaultsInstance].thirdLevel > -1) {
			if (i == [GeoDefaults sharedGeoDefaultsInstance].thirdLevel) {
				restoredJournal = j;
				TRACE("%s, restore index: %d\n", __func__, i);
			}
		}
		TRACE("%s, 0x%p, %s, lg: %f, lt: %f\n", __func__, self, [j.title UTF8String], longitude, latitude);
		
		mark.journalForLocation = j;
		mark.active = YES;
		mark.indexForJournal = i;
		[self.markArray addObject:mark];
		[self.markInViewArray addObject:mark];
		[self._mapView addAnnotation:mark];
		[self._mapView selectAnnotation:mark animated:YES];
		[mark release];
		
		if (n > 0) {
			delta.latitudeDelta = fabs(coord.latitude - latitude);
			delta.longitudeDelta = fabs(coord.longitude - longitude);
		}
		else {
			coord.latitude = latitude; coord.longitude = longitude;
			current.latitudeDelta = current.longitudeDelta = 0.0;
		}
		
		/*
         if (n<=1) {
         current = delta;
         }
         else {
         if (current.latitudeDelta < delta.latitudeDelta)
         current.latitudeDelta = delta.latitudeDelta;
         if (current.longitudeDelta < delta.longitudeDelta) 
         current.longitudeDelta = delta.longitudeDelta;
         }
		 */
		current.latitudeDelta += delta.latitudeDelta;
		current.longitudeDelta += delta.longitudeDelta;
		
		if (++n >= size)
			break;
		
	}
	
	if (n == 0 && self._noLocationWarning == nil && _locationLoaded == NO) {
		// No map entry
		UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nolocation-warning.png"]];
		self._noLocationWarning = view;
		
		float x = self.view.frame.size.width - view.frame.size.width;
		
		self._noLocationWarning.frame = CGRectMake(x/2.0, WARNING_Y, view.frame.size.width, view.frame.size.height);
		
		[self._mapView addSubview:self._noLocationWarning];
		[view release];
		
		// so that the resoration can start.
		[GeoDefaults sharedGeoDefaultsInstance].secondLevel = 0;
		[self._segmentControl setEnabled:NO forSegmentAtIndex:0];
		[self._segmentControl setEnabled:NO forSegmentAtIndex:1];
		
		self.navigationItem.leftBarButtonItem.enabled = NO;
		return;
	}
	else if (n > 0) {
		_locationLoaded = YES;
	}
	
	if (n > 0 && self._noLocationWarning != nil) {
		[self._noLocationWarning removeFromSuperview];
		self._noLocationWarning = nil;
		
		self.navigationItem.leftBarButtonItem.enabled = YES;
	}
	
	//(direction==MAP_MARK_ASCENDING?_currentJournalIndex += n:_currentJournalIndex -= n);
	numberOfItinerary = [journalArray count];
	markIndex = -1;
	centerCoordinate.latitude = avgLatitude/n; centerCoordinate.longitude = avgLongitude/n;
	
	// TODO: where is the center and how to decide span.
	MKCoordinateRegion region;
	region.center = centerCoordinate;
	TRACE("%s, latitide: %f, longitude: %f\n", __func__, region.center.latitude, region.center.longitude);
	TRACE("%s, latitude delta: %f, longitude delta: %f\n", __func__, current.latitudeDelta, current.longitudeDelta);
	//Set Zoom level using Span
	//MKCoordinateSpan span;
	//span.latitudeDelta=0.18;
	//span.longitudeDelta=0.18;
	
	region.span=current;
	centerRegion = [self._mapView regionThatFits:region];
	
	// Add center mark
	/*
     ItineraryMark *centerMark = [[ItineraryMark alloc] initWithLongitude:centerRegion.center.longitude withLatitude:centerRegion.center.latitude];
     centerMark.isCenter = YES;
     [self._mapView addAnnotation:centerMark];
     [self._mapView selectAnnotation:centerMark animated:YES];
     [centerMark release];
	 */
	// ---
	
	[self enableSegmentControlsFrom:i ToIndex:n];
	
	[self._mapView setRegion:centerRegion animated:YES];
	//[GeoDefaults sharedGeoDefaultsInstance].secondLevel = _currentJournalIndex;
	[GeoDefaults sharedGeoDefaultsInstance].secondLevel = 0;
	TRACE("%s, %d mark(s) added.\n", __func__, _currentJournalIndex+n);
}

- (NSInteger)getRealIndexForNextChunk:(NSInteger)chunk asending:(BOOL)asending actual:(NSInteger*)actual
{
	int n = 0;
	int i = _currentJournalIndex;
	Journal *j = nil;
	
	if (i >= [journalArray count]) {
		NSLog(@"%s, index error: %d", __func__, i);
		return 0;
	}
	do {
		j = [journalArray objectAtIndex:i];
		
		if (asending == YES)
			++i;
		else
			--i;
		
		if (j.address == nil) {
			continue;
		}
		
		if (++n >= chunk)
			break;
	} while ((asending == YES && i<[journalArray count]) || (asending == NO && i>0));
	
	if (actual)
		*actual = n;
	TRACE("%s, %d, n: %d\n", __func__, i, n);
	return i;
}

- (void)goPreviousMarks
{
	int size = _numberOfPins;
	
	if (_currentJournalIndex > 0 && _currentJournalIndex - _numberOfPins < 0) {
		size = _currentJournalIndex;
		_currentJournalIndex = 0;
        
	}
	else if (_currentJournalIndex <= 0) {
		NSLog(@"%s, index error: %d", __func__, _currentJournalIndex);
		return;
	}
	else {
		_currentJournalIndex = [self getRealIndexForNextChunk:_numberOfPins asending:NO actual:nil];
	}
	
	if (self._currentMark) {
		[self._mapView removeAnnotation:self._currentMark];
		self._currentMark = nil;
	}
	
	if (_currentJournalIndex >= 0) {
		[self._mapView removeAnnotations:markInViewArray];
		[self.markInViewArray removeAllObjects];
		
		[self addToMapWithDirection:MAP_MARK_DESCENDING upto:size];
        
	}
	else {
		[self._segmentControl setEnabled:NO forSegmentAtIndex:0];
	}
	
}

- (void)goNextMarks
{
	int actual = 0;
	
	if (_currentJournalIndex >= [self.journalArray count]) {
		NSLog(@"%s, index error: %d", __func__, _currentJournalIndex);
		return;
	}
	
	if (self._currentMark) {
		[self._mapView removeAnnotation:self._currentMark];
		self._currentMark = nil;
	}
	
	// Move the current to the begining of the next
	_currentJournalIndex = [self getRealIndexForNextChunk:_numberOfPins asending:YES actual:nil];
	[self getRealIndexForNextChunk:_numberOfPins asending:YES actual:&actual];
	if (actual > 0) {
		[self._mapView removeAnnotations:markInViewArray];
		[self.markInViewArray removeAllObjects];
		
		[self addToMapWithDirection:MAP_MARK_ASCENDING upto:_numberOfPins];
	}
	else {
		[self._segmentControl setEnabled:NO forSegmentAtIndex:1];
	}
	
	
}

- (IBAction)segmentAction:(id)sender
{
	// The segmented control was clicked, handle it here 
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	TRACE("Segment clicked: %d\n", segmentedControl.selectedSegmentIndex);
	
	switch (segmentedControl.selectedSegmentIndex) {
		case 0:
			[self goPreviousMarks];
			break;
		case 1:
			[self goNextMarks];
			break;
		case 2:
		default:
			NSLog(@"%s, index error: %d", __func__, segmentedControl.selectedSegmentIndex);
	}
	
}

- (void)resetMarks
{
	[self._mapView removeAnnotations:markInViewArray];
	[self.markInViewArray removeAllObjects];
	[self.markArray removeAllObjects];	
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self._mapView removeAnnotations:self._mapView.annotations];	
	[self.markArray removeAllObjects];
	[self.markInViewArray removeAllObjects];
	
	self._mapView = nil;

	
	self.markArray = nil;
	self.markInViewArray = nil;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [_titleLabel release];
	[_segmentControlButton release];
	[_noLocationWarning release];
	[_category release];
	[_mapView release];
	[categoryArray release];

	[markArray release];
	[markInViewArray release];

	[restoredJournal release];
	[_segmentControl release];
	[journalArray release];
	[_enumerator release];
	[_currentMark release];
    
    [super dealloc];
}

@end
