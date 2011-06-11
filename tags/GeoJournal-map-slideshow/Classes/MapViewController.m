//
//  MapViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/20/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "MapViewController.h"
#import "GeoDatabase.h"
#import "GeoDefaults.h"
#import "ItineraryMark.h"
#import "Category.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"

#define kViewTag					1
#define DEFAULT_ITINERARY_NUMBER	10
#define kCustomButtonHeight			30.0

#define MIN_SLIDER_VALUE			1.0
#define MAX_SLIDER_VALUE			10.0
#define INITIAL_SLIDE_WAITING_TIME	2.0
#define DEFAULT_SLIDER_VALUE		3.0

#define kConnectObjectKey	@"object"
#define kConnectHeaderKey	@"header"
#define kConnectFooterKey	@"footer"
#define kConnectRowsKey		@"rows"

#define MAP_TYPE_INDEX		0
#define CATEGORY_INDEX		1
#define NUM_LOCATION_INDEX	2

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
			num = 0;
			break;
		default:
			num = 0;
			NSLog(@"%s, index error: %d", __func__, index);
	}
	
	return num;
}

@implementation MapViewController

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
@synthesize _categoryType;
@synthesize _numLocation;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		self.prevButton = [UIImage imageNamed:@"prev.png"];
		self.nextButton = [UIImage imageNamed:@"next.png"];
		self.pauseButton = [UIImage imageNamed:@"pause-3.png"];
		self.stopButton = [UIImage imageNamed:@"stop-1.png"];
		detailDisclosureButtonType = nil;
		self.markArray = [[NSMutableArray alloc] initWithCapacity:DEFAULT_ITINERARY_NUMBER];
		self.markInViewArray = [[NSMutableArray alloc] initWithCapacity:DEFAULT_ITINERARY_NUMBER];
		didAlertViewShown = NO;
		
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
	
	//defaultTintColor = [segmentedControl.tintColor retain];	// keep track of this for later
	
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    [segmentedControl release];

	return segmentBarItem;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	categoryArray = [GeoDatabase sharedGeoDatabaseInstance].categoryArray;
	self.navigationItem.title = @"Itinerary";
	numberOfItinerary = DEFAULT_ITINERARY_NUMBER;
	avgLatitude = avgLongitude = 0.0;
	
	UIBarButtonItem *segmentBarItem = [self getPrevNextBarButton];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
    [segmentBarItem release];
	
	UIBarButtonItem *slideButton = [[UIBarButtonItem alloc]
									initWithTitle:@"Slideshow" style:UIBarButtonItemStylePlain target:self action:@selector(startSlideshow)];
	self.navigationItem.leftBarButtonItem = slideButton;
	[slideButton release];
	
	// Setting alert view
	self._slider.minimumValue = MIN_SLIDER_VALUE;
	self._slider.maximumValue = MAX_SLIDER_VALUE;
	self._slider.value = [[GeoDefaults sharedGeoDefaultsInstance].mapSlideShowInterval intValue];
	
	// Setting Map setting
	_mapType.selectedSegmentIndex = [[GeoDefaults sharedGeoDefaultsInstance].mapType intValue];
	_categoryType.selectedSegmentIndex = [[GeoDefaults sharedGeoDefaultsInstance].categoryType intValue];
	_numLocation.selectedSegmentIndex = [[GeoDefaults sharedGeoDefaultsInstance].numLocation intValue];
	
	self._mapView.mapType = self._mapType.selectedSegmentIndex;
	currentCategoryType = self._categoryType.selectedSegmentIndex;
	currentNumLocation = self._numLocation.selectedSegmentIndex;
	[self addToMap];
	[self.view addSubview:self._mapParentView];
}

- (Category*)getCategoryFromString:(NSString*)string 
{
	Category *c = nil;
	if ([string compare:NO_ACTIVE_CATEGORY] == NSOrderedSame) {
		c = [categoryArray objectAtIndex:0];
	}
	else {
		for (Category *t in categoryArray) {
			if ([t.name compare:string] == NSOrderedSame) {
				TRACE("%s, found category: %s\n", __func__, [string UTF8String]);
				c = t;
				break;
			}
		}
	}	
	
	return c;
}

- (Category*)getViewCategory
{
	Category *c = nil;
	NSString *categoryString = nil;
	switch (self._categoryType.selectedSegmentIndex) {
		case 0:
			//use the current selected category
			categoryString = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
			c = [self getCategoryFromString:categoryString];
			break;
		case 1:
		default:
			c = nil;
	}
	
	return c;
}

- (void)addToMap
{
	int n = 0;
	BOOL canContinue = YES;
	double latitude, longitude;
	CLLocationCoordinate2D centerCoordinate;
	CLLocationCoordinate2D coord;
	MKCoordinateSpan delta, current;
	Category *viewCategory = nil;
	
	numberOfItinerary = getNumberOfLocation(self._numLocation.selectedSegmentIndex);
	viewCategory = [self getViewCategory];
	avgLatitude = avgLongitude = 0.0;
	// Add location to map
	for (Category *c in categoryArray) {
		if (viewCategory && viewCategory !=c)
			continue;
		
		for (Journal *j in c.contents) {
			latitude = [j.latitude doubleValue];
			longitude = [j.longitude doubleValue];
			ItineraryMark *mark = [[ItineraryMark alloc] initWithLongitude:longitude withLatitude:latitude];
			avgLatitude += latitude; avgLongitude += longitude;
			
			//mark.titleForLocation = j.title;
			//mark.contentForLocation = j.text;
			//mark.imageForLocation = j.picture;
			mark.journalForLocation = j;
			mark.active = YES;
			[self.markArray addObject:mark];
			[self.markInViewArray addObject:mark];
			[self._mapView addAnnotation:mark];
			[self._mapView selectAnnotation:mark animated:YES];
			[mark release];
			
			if (n > 0) {
				delta.latitudeDelta = coord.latitude - latitude;
				delta.longitudeDelta = coord.longitude - longitude;
			}
			else {
				coord.latitude = latitude; coord.longitude = longitude;
				current.latitudeDelta = current.longitudeDelta = 0.0;
			}
			
			if (n<=1) {
				current = delta;
			}
			else {
				if (current.latitudeDelta < delta.latitudeDelta)
					current.latitudeDelta = delta.latitudeDelta;
				if (current.longitudeDelta < delta.longitudeDelta) 
					current.longitudeDelta = delta.longitudeDelta;
			}
			
			if (++n >= numberOfItinerary) {
				canContinue = NO;
				break;
			}
		}
		if (canContinue == NO)
			break;
	}
	
	markIndex = -1;
	centerCoordinate.latitude = avgLatitude/n; centerCoordinate.longitude = avgLongitude/n;
	/*
	n = 0;
	for (Category *c in categoryArray) {
		for (Journal *j in c.contents) {
			latitude = [j.latitude doubleValue];
			longitude = [j.longitude doubleValue];
			double d = sqrt(pow(centerCoordinate.latitude-latitude, 2) + pow(centerCoordinate.longitude-longitude, 2));
			TRACE("latitude: %f, longitude: %f, distance: %f\n", centerCoordinate.latitude-latitude, centerCoordinate.longitude-longitude, d);
			
			
			if (n++ >= numberOfItinerary)
				break;
		}
	}
	*/
	
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
	ItineraryMark *centerMark = [[ItineraryMark alloc] initWithLongitude:centerRegion.center.longitude withLatitude:centerRegion.center.latitude];
	centerMark.isCenter = YES;
	[self._mapView addAnnotation:centerMark];
	[self._mapView selectAnnotation:centerMark animated:YES];
	[centerMark release];
	// ---
	
	[self._mapView setRegion:centerRegion animated:YES];
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
	
	mark.active = YES;
	[self.markInViewArray addObject:mark];
	// TODO: to show this one is selected.
	[self._mapView addAnnotation:mark];
	TRACE("%s, %s\n", __func__, [mark.titleForLocation UTF8String]);
	
	// Change center.
	centerRegion.center.latitude = [mark.journalForLocation.latitude doubleValue];
	centerRegion.center.longitude = [mark.journalForLocation.longitude doubleValue];
	[self._mapView selectAnnotation:mark animated:YES];
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
	UIBarButtonItem *slideButton = [[UIBarButtonItem alloc]
									initWithTitle:@"Slideshow" style:UIBarButtonItemStylePlain target:self action:@selector(startSlideshow)];
	self.navigationItem.leftBarButtonItem = slideButton;
	[slideButton release];
	
	UIBarButtonItem *segmentBarItem = [self getPrevNextBarButton];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	[segmentBarItem release];
	markIndex = -1;
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

- (void)goNextMark
{
	if (markIndex == -1) {
		// Only when it starts, it will remove everything and redraw.
		[self._mapView removeAnnotations:markInViewArray];
		[self.markInViewArray removeAllObjects];
	}
	
	markIndex = (markIndex+1) % numberOfItinerary;
	ItineraryMark *mark = [self.markArray objectAtIndex:markIndex];
	
	[self addMarkToMapView:mark];	
}

- (IBAction)segmentAction:(id)sender
{
	// The segmented control was clicked, handle it here 
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	TRACE("Segment clicked: %d\n", segmentedControl.selectedSegmentIndex);
	
	switch (segmentedControl.selectedSegmentIndex) {
		case 0:
			[self goPreviousMark];
			break;
		case 1:
			[self goNextMark];
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
	else {
		if (markIndex + 1 < numberOfItinerary) {
			[self goNextMark];
		}
		else {
			// stop slide show.
			[timer invalidate];
			UIBarButtonItem *slideButton = [[UIBarButtonItem alloc]
											initWithTitle:@"Slideshow" style:UIBarButtonItemStylePlain target:self action:@selector(startSlideshow)];
			self.navigationItem.leftBarButtonItem = slideButton;
			[slideButton release];
			
			UIBarButtonItem *segmentBarItem = [self getPrevNextBarButton];
			self.navigationItem.rightBarButtonItem = segmentBarItem;
			[segmentBarItem release];
			
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
	float originY = self._mapView.frame.size.height-self._slideSubView.frame.size.height-90.0;
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
- (MKAnnotationView *) mapView:(MKMapView *)view viewForAnnotation:(id <MKAnnotation>) annotation
{
	//MKAnnotationView *annView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"currentloc"];
	//annView.animatesDrop=TRUE;
	NSString *reuseIdentifier = @"GoeItineraryCell";
	MKPinAnnotationView *annView = nil;
	
	annView = (MKPinAnnotationView*) [self._mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];
	if (annView == nil) {
		annView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
	}
	
	NSLog(@"%s: %p, %@", __func__, annView, [annotation title]);
	ItineraryMark *mark = (ItineraryMark*)annotation;
	
	if (mark.isCenter == YES) {
		//annView.enabled = TRUE;
		//annView.canShowCallout = YES;
		annView.animatesDrop = YES;
		[annView setPinColor:MKPinAnnotationColorGreen];
		//[annView setSelected:YES];
	}
	else {
		
		NSString *pictureLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:mark.imageForLocation];
		if (pictureLink) {
			//self.imageForJournal.frame = CGRectMake(IMAGE_X, IMAGE_Y, IMAGE_WIDTH, IMAGE_HEIGHT);
			UIImage *image = [[UIImage alloc] initWithContentsOfFile:pictureLink];
			UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
			imageView.frame = CGRectMake(0.0, 0.0, 30.0, 30.0);
			
			annView.canShowCallout = YES;
			annView.leftCalloutAccessoryView = imageView;
			mark.parentController = self;
			annView.rightCalloutAccessoryView = [self getDetailDisclosureButtonType:mark];
			//[annView.leftCalloutAccessoryView addSubview:imageView];
			[image release];
			[imageView release];
		}
		annView.enabled = TRUE;
		annView.animatesDrop = YES;
		if (mark.active) {
			[annView setPinColor:MKPinAnnotationColorRed];
		}
		else {
			[annView setPinColor:MKPinAnnotationColorGreen];
		}
		//[annView setSelected:YES];
	}
	
	return annView;
}

- (UIButton *)getDetailDisclosureButtonType:(ItineraryMark*)mark
{
	UIButton *button = nil;

	button = [[UIButton buttonWithType:UIButtonTypeDetailDisclosure] retain];
	button.frame = CGRectMake(250.0, 8.0, 25.0, 25.0);
	button.backgroundColor = [UIColor clearColor];
	[button addTarget:mark action:@selector(selectLocation:) forControlEvents:UIControlEventTouchUpInside];
	
	button.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells

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
	
	UIBarButtonItem *slideButton = [[UIBarButtonItem alloc]
									initWithTitle:@"Slideshow" style:UIBarButtonItemStylePlain target:self action:@selector(startSlideshow)];
	self.navigationItem.leftBarButtonItem = slideButton;
	[slideButton release];

	self.navigationItem.title = @"Itinerary";
	
	// TODO: Apply new settings
	self._mapView.mapType = self._mapType.selectedSegmentIndex;
	if (currentCategoryType != self._categoryType.selectedSegmentIndex ||
		currentNumLocation != self._numLocation.selectedSegmentIndex) {
		[self._mapView removeAnnotations:markInViewArray];
		[self.markInViewArray removeAllObjects];

		[self addToMap];
		currentNumLocation = self._numLocation.selectedSegmentIndex;
		currentCategoryType = self._categoryType.selectedSegmentIndex;
	}
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
	[GeoDefaults sharedGeoDefaultsInstance].categoryType = [NSNumber numberWithInt:self._categoryType.selectedSegmentIndex];
	[GeoDefaults sharedGeoDefaultsInstance].numLocation = [NSNumber numberWithInt:self._numLocation.selectedSegmentIndex];
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
/*
- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}
 */

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

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self._mapView = nil;
	self._slideSubView = nil;
	self._slider = nil;
	self._settingView = nil;
	self._mapParentView = nil;
	self._numLocation = nil;
	self._mapType = nil;
	self._categoryType = nil;
}


- (void)dealloc {
	[_numLocation release];
	[_mapType release];
	[_categoryType release];
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
	
    [super dealloc];
}


@end
