//
//  MapViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/20/09.
//  Copyright 2009 Home. All rights reserved.
//
#import <SystemConfiguration/SystemConfiguration.h>

#import "MapViewController.h"
#import "GeoDatabase.h"
#import "GeoDefaults.h"
#import "ItineraryMark.h"
#import "GCategory.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "JournalEntryViewController.h"

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
#define NUMBER_OF_MARK_CHUNK		5

extern NSString *getThumbnailFilename(NSString *filename);
extern NSString *getThumbnailOldFilename(NSString *filename);
extern Boolean testReachability();

NSInteger getNumberOfLocation(int index) 
{
	NSInteger num = 0;
	switch (index) {
		case 0:
			num = 5;
			break;
		case 1:
			num = 10;
			break;
		case 2:
			num = 20;
			break;
		case 3:
			num = -1;
			break;
		default:
			num = 0;
			NSLog(@"%s, index error: %d", __func__, index);
	}
	
	return num;
}

/*
 A = LAT1, B = LONG1
 C = LAT2, D = LONG2 (all converted to radians: degree/57.29577951)
 
 IF A = C AND B = D THEN DISTANCE = 0; 
 ELSE
 
 IF [SIN(A)SIN(C)+COS(A)COS(C)COS(B-D)] > 1 THEN DISTANCE = 
 3963.1*ARCOS[1]; // solved a prob I ran into.  I haven't fully  analyzed it yet                   
 ELSE
 DISTANCE=3963.1*ARCOS[SIN(A)SIN(C)+COS(A)COS(C)COS(B-D)];
 */


@implementation MapViewController

@synthesize _category;
@synthesize _infoButton;
@synthesize _mapParentView;
@synthesize _mapView;
@synthesize _settingView;
@synthesize categoryArray;
@synthesize prevButton;
@synthesize nextButton;
@synthesize pauseButton;
@synthesize stopButton;
@synthesize markArray;
@synthesize markInViewArray;
@synthesize _slideSubView;
@synthesize _slider;
@synthesize slideShowTimer;
@synthesize _mapType;
@synthesize restoredJournal;
@synthesize _segmentControl;
@synthesize journalArray;
@synthesize _currentMark;
@synthesize _enumerator;
@synthesize _noLocationWarning;
@synthesize _slideshowButton;
@synthesize _segmentControlButton;
@synthesize _titleLabel;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		detailDisclosureButtonType = nil;
		
		didAlertViewShown = NO;
		_currentJournalIndex = 0;
		_locationLoaded = NO;
    }
    return self;
}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/
- (UIBarButtonItem*)getPrevNextBarButton
{
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:@"prev.png"],
											 [UIImage imageNamed:@"next.png"],
											 nil]];
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	self._segmentControl = segmentedControl;
	
	//defaultTintColor = [segmentedControl.tintColor retain];	// keep track of this for later
	
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    [segmentedControl release];

	return segmentBarItem;
}

- (UIView*)getTitleView
{
#define	START_Y	10.0
	
	UIView *textView = [[UIView alloc] initWithFrame:CGRectMake(0.0, START_Y, 100.0, 50.0)];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, START_Y, 100.0, 20.0)];
	
	label.text = @"Itinerary";
	label.numberOfLines = 1;
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
	label.textAlignment = UITextAlignmentCenter;
	
	[textView addSubview:label];
	
	UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0.0, START_Y+20.0, 100.0, 20.0)];
	
	label1.text = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;//[NSString stringWithFormat:@"(%@)",[GeoDefaults sharedGeoDefaultsInstance].activeCategory];
	label1.numberOfLines = 1;
	label1.backgroundColor = [UIColor clearColor];
	label1.textColor = [UIColor whiteColor];
	label1.font = [UIFont fontWithName:@"HelveticaNeue" size:10];
	label1.textAlignment = UITextAlignmentCenter;
	self._titleLabel = label1;
	
	[textView addSubview:label1];
	
	[label release]; [label1 release];
	return textView;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.markArray = [[NSMutableArray alloc] initWithCapacity:DEFAULT_ITINERARY_NUMBER];
	self.markInViewArray = [[NSMutableArray alloc] initWithCapacity:DEFAULT_ITINERARY_NUMBER];
	
	self.prevButton = [UIImage imageNamed:@"prev.png"];
	self.nextButton = [UIImage imageNamed:@"next.png"];
	self.pauseButton = [UIImage imageNamed:@"pause-3.png"];
	self.stopButton = [UIImage imageNamed:@"stop-1.png"];
	
	self._category = nil;
	self.categoryArray = [GeoDatabase sharedGeoDatabaseInstance].categoryArray;
	//self.navigationItem.title = @"Itinerary";
	UIView *titleView = [self getTitleView];
	self.navigationItem.titleView = titleView;
	[titleView release];
	numberOfItinerary = DEFAULT_ITINERARY_NUMBER;
	avgLatitude = avgLongitude = 0.0;
	
	self._infoButton.frame = CGRectMake(self._infoButton.frame.origin.x, self._infoButton.frame.origin.y, INFO_BUTTON_WIDTH, INFO_BUTTON_HEIGHT);
	UIBarButtonItem *segmentBarItem = [self getPrevNextBarButton];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	self._segmentControlButton = segmentBarItem;
    [segmentBarItem release];
	
	UIBarButtonItem *slideButton = [[UIBarButtonItem alloc]
									initWithTitle:@"Slideshow" style:UIBarButtonItemStylePlain target:self action:@selector(startSlideshow)];
	self.navigationItem.leftBarButtonItem = slideButton;
	self._slideshowButton = slideButton;
	[slideButton release];
	
	// Setting alert view
	self._slider.minimumValue = MIN_SLIDER_VALUE;
	self._slider.maximumValue = MAX_SLIDER_VALUE;
	self._slider.value = [[GeoDefaults sharedGeoDefaultsInstance].mapSlideShowInterval intValue];
	
	// Setting Map setting
	_mapType.selectedSegmentIndex = [[GeoDefaults sharedGeoDefaultsInstance].mapType intValue];
	
	self._mapView.mapType = self._mapType.selectedSegmentIndex;
	
	self.tabBarController.tabBar.selectedItem.title = @"Itinerary";
	[self.view addSubview:self._mapParentView];
	
	if (testReachability() == false) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Map Warning" message:@"Internet connection is not available. Your map may not be available. Please check your Internet connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	TRACE("%s, %d\n", __func__, self.interfaceOrientation);
    
    DEBUG_RECT("view", self.view.frame);
	DEBUG_RECT("map", self._mapView.frame);
	DEBUG_RECT("superview", self._mapParentView.frame);
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

#pragma mark TOOLBAR ACTIONS

/* MAP callout view problem:
 *   sometimes it does not show it. 
 */
- (void)addMarkToMapView:(ItineraryMark*)mark
{
	// Change status of others
	//for (ItineraryMark *m in markInViewArray) {
	//	m.active = NO;
	//}
	//[self._mapView removeAnnotations:self.markInViewArray];
	//[self.markInViewArray removeAllObjects];
	
	mark.active = YES;
	//[self.markInViewArray addObject:mark];
	// TODO: to show this one is selected.
	[self._mapView addAnnotation:mark];
	TRACE("%s, %s\n", __func__, [mark.titleForLocation UTF8String]);
	
	// Change center.
	centerRegion.center.latitude = [mark.journalForLocation.latitude doubleValue];
	centerRegion.center.longitude = [mark.journalForLocation.longitude doubleValue];
	centerRegion.span.longitudeDelta = centerRegion.span.latitudeDelta = DEFAULT_MAP_SPAN;
	[self._mapView selectAnnotation:mark animated:YES];
	//MKCoordinateRegion region = [self._mapView regionThatFits:centerRegion];
	[self._mapView setRegion:centerRegion animated:YES];	
}

- (void)pauseSlideShow:(id)sender
{
	UIBarButtonItem *play = [[UIBarButtonItem alloc]
							 initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(continueSlideShow:)];
	self.navigationItem.leftBarButtonItem = play;
	[play release];
	
	[self.slideShowTimer invalidate];
}

- (void)continueSlideShow:(id)sender
{
	UIBarButtonItem *pause = [[UIBarButtonItem alloc]
							  initWithImage:pauseButton style:UIBarButtonItemStylePlain target:self action:@selector(pauseSlideShow:)];
	self.navigationItem.leftBarButtonItem = pause;
	[pause release];

	NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop]; 
	NSDate* futureDate = [NSDate dateWithTimeIntervalSinceNow:0.5]; 
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:futureDate
											  interval:self._slider.value
												target:self
											  selector:@selector(showNextLocation:) 
											  userInfo:nil 
											   repeats:YES]; 
	self.slideShowTimer = timer;
	[myRunLoop addTimer:self.slideShowTimer forMode:NSDefaultRunLoopMode]; 
	[timer release];		
	
}

- (void)stopSlideShow:(id)sender
{
	[self.slideShowTimer invalidate];
	self.slideShowTimer = nil;
	UIBarButtonItem *slideButton = [[UIBarButtonItem alloc]
									initWithTitle:@"Slideshow" style:UIBarButtonItemStylePlain target:self action:@selector(startSlideshow)];
	self.navigationItem.leftBarButtonItem = slideButton;
	[slideButton release];
	
	UIBarButtonItem *segmentBarItem = [self getPrevNextBarButton];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	[segmentBarItem release];
	self._enumerator = nil;
	
	// Enable segment control
	
	_currentJournalIndex = markIndex;
	[self enableSegmentControlsFrom:_currentJournalIndex ToIndex:0];
	[UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)goPreviousMark
{
	if (markIndex == -1) {
		// Only when it starts, it will remove everything and redraw.
		[self._mapView removeAnnotations:markInViewArray];
		[self.markInViewArray removeAllObjects];
	}
	
	if (markIndex - 1 < 0)
		markIndex = numberOfItinerary;
	
	markIndex = (markIndex-1) % numberOfItinerary;
	ItineraryMark *mark = [self.markArray objectAtIndex:markIndex];
	
	[self addMarkToMapView:mark];	
	
}

- (BOOL)goNextMark
{
	Journal *j = nil;
	
	if (self._enumerator == nil) {
		self._enumerator = [journalArray objectEnumerator];
	
		// Only when it starts, it will remove everything and redraw.
		[self._mapView removeAnnotations:markInViewArray];
		[self.markInViewArray removeAllObjects];
		markIndex = 0;
	}
	int n=0;
	do {
		j = [self._enumerator nextObject]; 
		n++;
	} while (j!=nil && j.address == nil);
	if (j == nil)
		return NO;
	
	if (self._currentMark) {
		[self._mapView removeAnnotation:self._currentMark];
	}
	
	ItineraryMark *mark = [self getMarkFromJournal:j];
	markIndex += n;
	mark.indexForJournal = markIndex;
	
	TRACE("%s, 0x%p, %s\n", __func__, self, [j.title UTF8String]);
	[self addMarkToMapView:mark];	
	self._currentMark = mark;
	[mark release];
	
	return YES;
}

- (void)goPreviousMarks
{
	int size = NUMBER_OF_MARK_CHUNK;
	
	if (_currentJournalIndex > 0 && _currentJournalIndex - NUMBER_OF_MARK_CHUNK < 0) {
		size = _currentJournalIndex;
		_currentJournalIndex = 0;
	
	}
	else if (_currentJournalIndex <= 0) {
		NSLog(@"%s, index error: %d", __func__, _currentJournalIndex);
		return;
	}
	else {
		_currentJournalIndex = [self getRealIndexForNextChunk:NUMBER_OF_MARK_CHUNK asending:NO actual:nil];
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
	_currentJournalIndex = [self getRealIndexForNextChunk:NUMBER_OF_MARK_CHUNK asending:YES actual:nil];
	[self getRealIndexForNextChunk:NUMBER_OF_MARK_CHUNK asending:YES actual:&actual];
	if (actual > 0) {
		[self._mapView removeAnnotations:markInViewArray];
		[self.markInViewArray removeAllObjects];
		
		[self addToMapWithDirection:MAP_MARK_ASCENDING upto:NUMBER_OF_MARK_CHUNK];
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

- (void)showNextLocation:(NSTimer*)timer
{
	if (didAlertViewShown == YES && sliderBeingUsed == NO) {
		// take out this first.
		CGContextRef context = UIGraphicsGetCurrentContext();
		[UIView beginAnimations:nil context:context];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:0.5];
		
		CGRect rect = [self._slideSubView frame];
		rect.origin.y = 380.0; //-80.0f - rect.size.height;
		[self._slideSubView setFrame:rect];
		
		// Complete the animation
		[UIView commitAnimations];		
		didAlertViewShown = NO;
		
		[timer invalidate];
		
		NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop]; 
		NSDate* futureDate = [NSDate dateWithTimeIntervalSinceNow:self._slider.value]; 
		NSTimer *timer = [[NSTimer alloc] initWithFireDate:futureDate
														   interval:self._slider.value
															 target:self
														   selector:@selector(showNextLocation:) 
														   userInfo:nil 
															repeats:YES]; 
		self.slideShowTimer = timer;
		[myRunLoop addTimer:self.slideShowTimer forMode:NSDefaultRunLoopMode]; 
		[timer release];		
		TRACE("%s, schedule : %f\n", __func__, self._slider.value);
		[GeoDefaults sharedGeoDefaultsInstance].mapSlideShowInterval = [NSNumber numberWithInt:self._slider.value];
		[self goNextMark];
	}
	else if (sliderBeingUsed == NO) {
		if ([self goNextMark] == NO) {
			// stop slide show.
			[timer invalidate];
			UIBarButtonItem *slideButton = [[UIBarButtonItem alloc]
											initWithTitle:@"Slideshow" style:UIBarButtonItemStylePlain target:self action:@selector(startSlideshow)];
			self.navigationItem.leftBarButtonItem = slideButton;
			[slideButton release];
			
			UIBarButtonItem *segmentBarItem = [self getPrevNextBarButton];
			self.navigationItem.rightBarButtonItem = segmentBarItem;
			[segmentBarItem release];
			self._enumerator = nil;
			
			// Enable segment control
			_currentJournalIndex = markIndex-1;
			[self enableSegmentControlsFrom:_currentJournalIndex ToIndex:0];
			self.slideShowTimer = nil;
			[UIApplication sharedApplication].idleTimerDisabled = NO;
		}
	}
	
}

- (IBAction)sliderTouchEnd:(id)sender
{
	TRACE_HERE;
	sliderBeingUsed = NO;
}

- (IBAction)sliderValueChanged:(id)sender
{
	TRACE_HERE;
	sliderBeingUsed = YES;
}

// Use "idleTimerDisable = YES".
- (void)startSlideshow
{
	sliderBeingUsed = NO;
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	float originY = self._mapView.frame.size.height-self._slideSubView.frame.size.height;
	self._slideSubView.frame = CGRectMake(0.0, originY,
										   self._slideSubView.frame.size.width, self._slideSubView.frame.size.height);
	TRACE("%s, x: %f, y: %f, w: %f, h: %f\n", __func__, self._slideSubView.frame.origin.x, 
											self._slideSubView.frame.origin.y,
											self._slideSubView.frame.size.width,
											self._slideSubView.frame.size.height);
	//self._slideSubView 
	[self.view addSubview:self._slideSubView];
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.9];
	
	CGRect rect = [self._slideSubView frame];
	rect.origin.y = originY; //380.0f;
	[self._slideSubView setFrame:rect];
	[UIView commitAnimations];
	didAlertViewShown = YES;
	
	// Chanage to pause button
	UIBarButtonItem *pause = [[UIBarButtonItem alloc]
									initWithImage:pauseButton style:UIBarButtonItemStylePlain target:self action:@selector(pauseSlideShow:)];
	self.navigationItem.leftBarButtonItem = pause;
	[pause release];
	
	UIBarButtonItem *stop = [[UIBarButtonItem alloc]
							  initWithImage:stopButton style:UIBarButtonItemStylePlain target:self action:@selector(stopSlideShow:)];
	self.navigationItem.rightBarButtonItem = stop;
	[stop release];
	
	
	// ---
	
	
	NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop]; 
	// Create and schedule the first timer. 
	self._currentMark = nil;
	NSDate* futureDate = [NSDate dateWithTimeIntervalSinceNow:INITIAL_SLIDE_WAITING_TIME]; 
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:futureDate
														interval:DEFAULT_SLIDER_VALUE
														target:self
														selector:@selector(showNextLocation:) 
														userInfo:nil 
														repeats:YES]; 
	self.slideShowTimer = timer;
	[myRunLoop addTimer:self.slideShowTimer forMode:NSDefaultRunLoopMode]; 
	[timer release];
}

#pragma mark -
#pragma mark MKMapView Delegate
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	TRACE_HERE;
}


- (MKAnnotationView *) mapView:(MKMapView *)view viewForAnnotation:(id <MKAnnotation>) annotation
{
	BOOL reuseAnnView = YES, reuseImageView = YES;
	NSString *reuseIdentifier = @"GoeItineraryCell";
	MKPinAnnotationView *annView = nil;
	
	annView = (MKPinAnnotationView*) [self._mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];
	if (annView == nil) {
		annView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier] autorelease];
		reuseAnnView = NO;
	}
	
	ItineraryMark *mark = (ItineraryMark*)annotation;
	
	if (mark.isCenter == YES) {
		//annView.enabled = TRUE;
		//annView.canShowCallout = YES;
		annView.animatesDrop = YES;
		[annView setPinColor:MKPinAnnotationColorGreen];
		//[annView setSelected:YES];
	}
	else {
		// TODO: use tag in the imageview.
		NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:mark.imageForLocation];
		if (pictureLink) {
			NSString *thumb = getThumbnailFilename(pictureLink);
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:thumb] == NO) {
				thumb = getThumbnailOldFilename(pictureLink);
			}
			NSData *data = [[NSData alloc] initWithContentsOfFile:thumb];
			TRACE("%s, %s, %d\n", __func__, [pictureLink UTF8String], [data length]);
			
			UIImage *image = [[UIImage alloc] initWithData:data];
			UIImageView *imageView = (UIImageView*) [annView.leftCalloutAccessoryView viewWithTag:kThumbImageViewTag];
			if (imageView == nil) {
				imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
				imageView.tag = kThumbImageViewTag;
				reuseImageView = NO;
				annView.leftCalloutAccessoryView = imageView;
			}
			else {
				imageView.image = [[UIImage alloc] initWithCGImage:image.CGImage scale:THUMBNAIL_RATIO orientation:UIImageOrientationUp];
			}
			
			imageView.frame = CGRectMake(0.0, 0.0, 30.0, 30.0);
			
			annView.canShowCallout = YES;

			//[thumb release];
			[data release];
			[image release];
		}
		else {
			annView.canShowCallout = YES;
			annView.leftCalloutAccessoryView = nil;
		}
		mark.parentController = self;
		//TRACE("%s: %p, %s, %p\n", __func__, annView, [[annotation title] UTF8String], annView.rightCalloutAccessoryView);
		
		annView.rightCalloutAccessoryView = [self getDetailDisclosureButtonType:mark fromAnnotationView:annView];
			//[annView.leftCalloutAccessoryView addSubview:imageView];

		TRACE("%s, %s, ann: %d, image: %d\n", __func__, [mark.journalForLocation.title UTF8String], reuseAnnView, reuseImageView);
		annView.enabled = TRUE;
		annView.animatesDrop = YES;
		if (mark.active) {
			[annView setPinColor:MKPinAnnotationColorRed];
		}
		else {
			[annView setPinColor:MKPinAnnotationColorGreen];
		}
		[annView setSelected:YES];
	}
	
	return annView;
}

- (UIButton *)getDetailDisclosureButtonType:(ItineraryMark*)mark fromAnnotationView:(MKAnnotationView*)annView;
{
	UIButton *button = nil;

	if (mark) {
		//button = (UIButton*)[annView.rightCalloutAccessoryView viewWithTag:kViewTag];
		//if (button == nil) {
			button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			//button.frame = //CGRectMake(250.0, 8.0, 25.0, 25.0);
			button.backgroundColor = [UIColor clearColor];
			[button addTarget:mark action:@selector(selectLocation:) forControlEvents:UIControlEventTouchUpInside];
		
			button.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells
		/*}
		else {
			NSSet *targets = [button allTargets];
			id object = nil;
			if (targets && (object = [targets anyObject])) {
				[button removeTarget:object action:@selector(selectLocation) forControlEvents:UIControlEventTouchUpInside];
			}
			[button addTarget:mark action:@selector(selectLocation:) forControlEvents:UIControlEventTouchUpInside];
		}
		 */
		
		button.enabled = YES;
		button.showsTouchWhenHighlighted = YES;
		//button.userInteractionEnabled = NO;
		TRACE("%s, button status: %d\n", __func__, button.enabled);
	}

	return button;
}

- (UIButton *)detailDisclosureButtonType
{
	if (detailDisclosureButtonType == nil)
	{
		// create a UIButton (UIButtonTypeDetailDisclosure)
		detailDisclosureButtonType = [[UIButton buttonWithType:UIButtonTypeDetailDisclosure] retain];
		detailDisclosureButtonType.frame = CGRectMake(250.0, 8.0, 25.0, 25.0);
		//[detailDisclosureButtonType setTitle:@"Detail Disclosure" forState:UIControlStateNormal];
		detailDisclosureButtonType.backgroundColor = [UIColor clearColor];
		[detailDisclosureButtonType addTarget:self action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];
		
		detailDisclosureButtonType.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells
	}
	return detailDisclosureButtonType;
}


#pragma mark -


#pragma mark MAP SETTING VIEW 
- (void)mapSettingDone:(id)sender
{
	UIBarButtonItem *segmentBarItem = [self getPrevNextBarButton];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
    [segmentBarItem release];
	
	//UIBarButtonItem *slideButton = [[UIBarButtonItem alloc]
	//								initWithTitle:@"Slideshow" style:UIBarButtonItemStylePlain target:self action:@selector(startSlideshow)];
	self.navigationItem.leftBarButtonItem = self._slideshowButton; //slideButton;
	//[slideButton release];
	self.navigationItem.rightBarButtonItem = self._segmentControlButton;

	self.navigationItem.title = @"Itinerary";
	
	// TODO: Apply new settings
	self._mapView.mapType = self._mapType.selectedSegmentIndex;
	// ---
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationTransition: UIViewAnimationTransitionCurlDown forView:self.view cache:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];
	
	// Animations
	//[self.view exchangeSubviewAtIndex:1 withSubviewAtIndex:0];
	[self._settingView removeFromSuperview];
	[self.view addSubview:self._mapParentView];
	
	// Commit Animation Block
	[UIView commitAnimations];
	
	[GeoDefaults sharedGeoDefaultsInstance].mapType = [NSNumber numberWithInt:self._mapType.selectedSegmentIndex];

	[[GeoDefaults sharedGeoDefaultsInstance] saveMapSettins];
}

- (IBAction)goSetting:(id)sender
{
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(mapSettingDone:)];
	
	self.navigationItem.leftBarButtonItem = button;
	[button release];
	self.navigationItem.rightBarButtonItem = nil;
	self.navigationItem.title = @"Itinerary Setting";
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationTransition: UIViewAnimationTransitionCurlUp forView:self.view cache:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];
	
	self._settingView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	// Animations
	//[self.view exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
	[self._mapParentView removeFromSuperview];
	[self.view addSubview:self._settingView];
	
	// Commit Animation Block
	[UIView commitAnimations];
	
}
#pragma mark -

- (void)resetMarks
{
	[self._mapView removeAnnotations:markInViewArray];
	[self.markInViewArray removeAllObjects];
	[self.markArray removeAllObjects];	
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if ([GeoDefaults sharedGeoDefaultsInstance].levelRestored == NO) {
		[self restoreLevel];
	}
	else {
		if (self._category == nil) {
			// View loaded first.
			[self addToMapWithDirection:MAP_MARK_ASCENDING upto:NUMBER_OF_MARK_CHUNK];
			self._category = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
		} else if ([[GeoDefaults sharedGeoDefaultsInstance] needRefreshCategory:self._category]) {
			// Need to reload
			_locationLoaded = NO;
			_currentJournalIndex = 0;
			[self resetMarks];
			[self addToMapWithDirection:MAP_MARK_ASCENDING upto:NUMBER_OF_MARK_CHUNK];
			self._category = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
			self._titleLabel.text = self._category;
		} else {
			// see if the number of journal has been changed or not.
			NSArray *array = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:[self getViewCategory]];
			if ([array count] != [self.journalArray count]) {
				[self resetMarks];
				[self addToMapWithDirection:MAP_MARK_ASCENDING upto:NUMBER_OF_MARK_CHUNK];
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
		[self addToMapWithDirection:MAP_MARK_ASCENDING upto:NUMBER_OF_MARK_CHUNK];
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


/* TODO: stop the timer if it is running.
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */

/*
 - (void)viewDidDisappear:(BOOL)animated {
	 [super viewDidDisappear:animated];
 }
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#ifdef ALLOW_ROTATING
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    TRACE_HERE;
    
    return YES;
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    CGRect bounds = self.view.bounds;
   
    //self.navigationController.hidesBottomBarWhenPushed = YES;
    self.navigationController.toolbarHidden = YES;
	DEBUG_RECT("view", self.view.bounds);
	DEBUG_RECT("map", self._mapView.frame);
	
    self._mapView.frame = bounds;
    //CGRect frame = CGRectMake(self.buttonView.frame.origin.x, self.buttonView.frame.origin.y, 
    //                          bounds.size.width, self.buttonView.frame.size.height);

}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	TRACE_HERE;
	DEBUG_RECT("view", self.view.frame);
	DEBUG_RECT("map", self._mapView.frame);
	DEBUG_RECT("superview", self.view.superview.frame);
	
	//[self._mapView removeFromSuperview];
}
#endif

- (void)adjustOrientation:(CGRect)bounds
{
    self.navigationController.toolbarHidden = YES;
	DEBUG_RECT("view", self.view.bounds);
	DEBUG_RECT("map", self._mapView.frame);
	
    self._mapView.frame = bounds;
    
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	TRACE_HERE;
	
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	TRACE_HERE;
	//[self._mapView removeAnnotations:markInViewArray];
	[self._mapView removeAnnotations:self._mapView.annotations];	
	[self.markArray removeAllObjects];
	[self.markInViewArray removeAllObjects];
	
	self._mapView = nil;
	self._slideSubView = nil;
	self._slider = nil;
	self._settingView = nil;
	self._mapParentView = nil;
	self._mapType = nil;
	self._infoButton = nil;
	
	self.prevButton = nil;
	self.nextButton = nil;
	self.pauseButton = nil;
	self.stopButton = nil;
	
	self.markArray = nil;
	self.markInViewArray = nil;
	
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (self.slideShowTimer != nil)
		[self stopSlideShow:nil];
}

- (void)dealloc {
	TRACE_HERE;
	[_titleLabel release];
	[_segmentControlButton release];
	[_slideshowButton release];
	[_noLocationWarning release];
	[_category release];
	[_infoButton release];
	[_mapType release];
	[_mapParentView release];
	[stopButton release];
	[pauseButton release];
	[_slideSubView release];
	[_slider release];
	[_mapView release];
	[categoryArray release];
	[prevButton release];
	[nextButton release];
	[markArray release];
	[markInViewArray release];
	[slideShowTimer release];
	[_settingView release];
	[restoredJournal release];
	[_segmentControl release];
	[journalArray release];
	[_enumerator release];
	[_currentMark release];
	
    [super dealloc];
}


@end
