//
//  MapViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/20/09.
//  Copyright 2009 Home. All rights reserved.
//
#import <SystemConfiguration/SystemConfiguration.h>

#import "MapViewController.h"

#define NUMBER_OF_MARK_CHUNK		5

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

@synthesize _infoButton;
@synthesize _mapParentView;
@synthesize _settingView;

@synthesize prevButton;
@synthesize nextButton;
@synthesize pauseButton;
@synthesize stopButton;

@synthesize _slideSubView;
@synthesize _slider;
@synthesize slideShowTimer;
@synthesize _mapType;


@synthesize _slideshowButton;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		detailDisclosureButtonType = nil;
		
		didAlertViewShown = NO;
		_currentJournalIndex = 0;
		_locationLoaded = NO;
        _numberOfPins = NUMBER_OF_MARK_CHUNK;
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
	TRACE_HERE;
	
	self.prevButton = [UIImage imageNamed:@"prev.png"];
	self.nextButton = [UIImage imageNamed:@"next.png"];
	self.pauseButton = [UIImage imageNamed:@"pause-3.png"];
	self.stopButton = [UIImage imageNamed:@"stop-1.png"];
	
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
	
    
    DEBUG_RECT("view", self.view.frame);
	DEBUG_RECT("map", self._mapView.frame);
	DEBUG_RECT("superview", self._mapParentView.frame);
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
	//[self._mapView removeAnnotations:markInViewArray];
	
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (self.slideShowTimer != nil)
		[self stopSlideShow:nil];
}

- (void)dealloc {
	TRACE_HERE;
   	[_slideshowButton release];
	[_infoButton release];
	[_mapType release];
	[_mapParentView release];
	[stopButton release];
	[pauseButton release];
	[_slideSubView release];
	[_slider release];
	[prevButton release];
   	[nextButton release];
    [slideShowTimer release];
	[_settingView release];
	
    [super dealloc];
}


@end
