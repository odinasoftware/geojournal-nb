//
//  HorizontalViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/30/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "HorizontalViewController.h"
#import "GeoDatabase.h"
#import "Journal.h"
#import "GCategory.h"
#import "GeoJournalHeaders.h"
#import "HorizontalImageViewController.h"
#import "GeoDefaults.h"

#define SCROLL_VIEW_HEIGHT			300.0
#define INITIAL_SLIDE_IMAGE			3
#define DEFAULT_NUMBER_OF_PAGES		20
#define MAX_CONTROLLER_NUM			3
#define DEFAULT_SLIDER_VALUE		2

#define INFO_BUTTON_X				440.0
#define INFO_BUTTON_Y				5.0

@implementation HorizontalPageViewControllerPointer

@synthesize page;
@synthesize controller;

- (id)initWithPage:(NSInteger)num
{
	if (self = [super init]) {
		page = num;
		controller = nil;
	}
	return self;
}

- (void)dealloc
{
	[controller release];
	[super dealloc];
}

@end

@implementation HorizontalViewController

@synthesize articleTitle;
@synthesize articleDescription;
@synthesize _contentView;
@synthesize _slider;
@synthesize _audioPlayButton;
@synthesize _player;
@synthesize _audioStopButton;
@synthesize _bigPlayButton;
@synthesize _bigStopButton;
@synthesize _audioButtonView;
@synthesize _playButtonView;
@synthesize _audioButton;
@synthesize _playButton;
@synthesize _imageView;
@synthesize _scrollView;
@synthesize categoryArray;
@synthesize journalArray;
@synthesize _showSlideShow;
@synthesize _enableAudio;
@synthesize _showContent;
@synthesize _settingView;
@synthesize _audioNoAvailButton;
@synthesize slideShowTimer;
@synthesize controllerArray;
@synthesize currentSlideImageController;
@synthesize _defaultCategory;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		currentPlayedPage = -1;
    }
    return self;
}

- (NSArray*)getPageControllerArray
{
	NSArray *a = nil;
	
	HorizontalPageViewControllerPointer *p1 = [[HorizontalPageViewControllerPointer alloc] initWithPage:-1];
	HorizontalPageViewControllerPointer *p2 = [[HorizontalPageViewControllerPointer alloc] initWithPage:-1];
	HorizontalPageViewControllerPointer *p3 = [[HorizontalPageViewControllerPointer alloc] initWithPage:-1];
	
	a = [[NSArray alloc] initWithObjects:p1, p2, p3, nil];
	[p1 release]; [p2 release]; [p3 release];
	
	return a;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self._audioStopButton = [UIImage imageNamed:@"Mike2-stop.png"];
	self._audioPlayButton = [UIImage imageNamed:@"Mike2.png"];
	self._bigStopButton = [UIImage imageNamed:@"big-stop.png"];
	self._bigPlayButton = [UIImage imageNamed:@"big-play.png"];
	self._audioNoAvailButton = [UIImage imageNamed:@"Mike-no-avail.png"];
	
	controllerArray = [self getPageControllerArray]; 
	currentArrayPointer = 0;
	currentPage = -1;
	
	self.categoryArray = [GeoDatabase sharedGeoDatabaseInstance].categoryArray;
	numberOfPages = [self setPagesForSlideShow];
	
	//scrollView.autoresizingMask = UIViewAutoresizingNone;
	//toolBar.autoresizingMask = UIViewAutoresizingNone;
	_scrollView.backgroundColor = [UIColor blackColor];
	_scrollView.pagingEnabled = YES;
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * numberOfPages, SCROLL_VIEW_HEIGHT);
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.scrollsToTop = NO;
    _scrollView.delegate = self;
	
	currentSelectedPage = 0;
	isSlideShowRunning = NO;
	
	self._playButtonView.frame = CGRectMake(10.0, 50.0, 40.0, 40.0);
	self._audioButtonView.frame = CGRectMake(10.0, 10.0, 40.0, 40.0);
	
	TRACE_HERE;
}

- (void)showNoImageWarning
{
	self.articleTitle.text = @"No picture found in this category.";
	self.articleDescription.text = @"No picture found in this categoy. Please select different category to view pictures";
	//self.articleDescription.font = [UIFont systemFontOfSize:15.0];
	//self.articleDescription.textColor = [UIColor whiteColor]; 
	
	//self._playButtonView.hidden = YES;
	//self._audioButtonView.hidden = YES;
	[self.view addSubview:[self getInfoButton]];
}

- (void)showGadgets:(UIView*)view;
{
	self._showSlideShow.on = [[GeoDefaults sharedGeoDefaultsInstance].showSlideshowInHorizontal boolValue];
	self._enableAudio.on = [[GeoDefaults sharedGeoDefaultsInstance].enableAudioInHorizontal boolValue];
	self._showContent.on = [[GeoDefaults sharedGeoDefaultsInstance].showContentInHorizontal boolValue];
	
	if (self._showSlideShow.on == YES) {
		[view addSubview:self._playButtonView];
	}
	
	if (self._enableAudio.on == YES) {
		[view addSubview:self._audioButtonView];
	}
	
	[view addSubview:[self getInfoButton]];
}

- (void)viewDidAppear:(BOOL)animated
{
	TRACE("%s, w: %f, h: %f\n", __func__, _scrollView.contentSize.width, _scrollView.contentSize.height);
	// TODO: The last one shows only. 
	int i = 0;
	if (numberOfPages == 0) {
		[self showNoImageWarning];
		[self loadImageView:0];
	}
	else {
		for (i=0; i<INITIAL_SLIDE_IMAGE; ++i) {
			[self loadImageView:i];
		}
		
		currentPage = i - 1; // represent the last loaded page
		[self showGadgets:self.view];
		[self showContentOfIndex:currentSelectedPage];
	}
}

- (NSInteger)setPagesForSlideShow
{
	NSArray *array = nil;
	
	for (GCategory *c in categoryArray) {
		if ([c.name compare:[GeoDefaults sharedGeoDefaultsInstance].activeCategory] == NSOrderedSame) {
			array = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:c];
		}
	}
	
	self.journalArray = array;	
	numberOfPages = [journalArray count];
	TRACE("%s, %d\n", __func__, numberOfPages);
	return numberOfPages;
}

- (Journal*)getJournalForPage:(NSInteger)page
{
	Journal *j = nil;
	if (page < [journalArray count]) {
		j = [journalArray objectAtIndex:page];
	}
	return j;
}

- (HorizontalImageViewController*)getNextImageViewControllerWithPage:(NSInteger)page needRedraw:(BOOL*)redraw
{
	int target = -1;
	
	if (currentPage == page || currentPage == -1) {
		// increasing
		target = currentArrayPointer;
		currentArrayPointer = (currentArrayPointer + 1) % MAX_CONTROLLER_NUM;
	}
	else if (currentPage == page + 2) {
		// decreasing
		currentArrayPointer--;
		if (currentArrayPointer < 0)
			currentArrayPointer = MAX_CONTROLLER_NUM - 1;
		target = currentArrayPointer;
	}
	else {
		NSLog(@"%s, unknown case: cur: %d, page: %d",__func__, currentPage, page);
		return nil;
	}
	
	TRACE("%s, cur: %d, page: %d, target: %d\n", __func__, currentPage, page, target); 
	HorizontalPageViewControllerPointer *pointer = [controllerArray objectAtIndex:target];
	if (pointer.controller == nil) {
		HorizontalImageViewController *c = [[HorizontalImageViewController alloc] initWithNibName:@"HorizontalImageViewController" withJournal:[self getJournalForPage:page]];
		pointer.controller = c;
		pointer.controller.view.tag = page;
		*redraw = NO;
		[c release];
	}
	else {
		*redraw = YES;
		[pointer.controller.view removeFromSuperview];
		pointer.controller.view.tag = page;
		
		//pointer.link = [storage getArticleAtPage:page];
	}
	
	pointer.page = page;
	
	return pointer.controller;
}


- (void)loadImageView:(NSInteger)page 
{
	BOOL shouldRedraw = NO;
	
	HorizontalImageViewController *controller = [self getNextImageViewControllerWithPage:page needRedraw:&shouldRedraw];
	
	//[controller._imageView addSubview:[self getInfoButton]];
	
	CGRect frame = _scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
	controller.view.frame = frame; //CGRectMake(frame.origin.x, frame.origin.y, controller.view.frame.size.width, controller.view.frame.size.height);
	
	if (self._showContent.on == NO) {
		[controller hideContent];
	}
	TRACE("%s, x: %f, y: %f, %d\n", __func__, frame.origin.x, frame.origin.y, shouldRedraw);
	if (shouldRedraw == NO) {
		
		[_scrollView addSubview:controller.view];
		//[self addToControllerArray:controller withPage:page forLink:controller.webLink];
	}
	else {
		
		[controller reDrawWithJournal:[self getJournalForPage:page]];
		
		[_scrollView addSubview:controller.view];
	}
	
	if ([[GeoDefaults sharedGeoDefaultsInstance].showContentInHorizontal boolValue] == NO) {
		self._contentView.hidden = YES;
		//[controller._sliderView removeFromSuperview];
	}
	
}

#pragma mark Button Outlets 

- (void)showContentOfIndex:(NSInteger)index
{
	Journal *j = [self getJournalForPage:index];
	if (j) {
		self.articleTitle.text = j.title;
		self.articleDescription.font = [UIFont systemFontOfSize:15.0];
		self.articleDescription.textColor = [UIColor whiteColor]; 
		self.articleDescription.text = j.text;
		if (j.audio == nil) {
			//self._audioButtonView.enabled = NO;
			[self._audioButton setBackgroundImage:self._audioNoAvailButton forState:UIControlStateNormal];
		}
		else {
			//self._audioButtonView.enabled = YES;
			[self._audioButton setBackgroundImage:self._audioPlayButton forState:UIControlStateNormal];
		}
	}
}

- (void)playLink:(NSString*)audioLink
{
	NSError *error = nil;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:audioLink] == YES) {
		NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:audioLink];
		AVAudioPlayer *audio = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
		
		self._player = audio;
		self._player.delegate = self;
		[audio release];
		[fileURL release];
		if (error) {
			NSLog(@"%s, %@", __func__, error);
			return;
		}
		currentPlayedPage = currentSelectedPage;
		[self._audioButton setBackgroundImage:self._audioStopButton forState:UIControlStateNormal];
		[self._player play];
	}
	else {
		NSLog(@"%s, file does not exist.", __func__);
	}
}

- (IBAction)playAudio:(id)sender
{
	
	HorizontalImageViewController *controller = [self getImageControllerWithPage:currentSelectedPage];
	
	if (controller) {
		Journal *j = [self getJournalForPage:currentSelectedPage];
		NSString *audioLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:j.audio];
		
		TRACE("%s, page: %d, link: %s\n", __func__, currentSelectedPage, [audioLink UTF8String]);
		if (audioLink == nil) {
			NSLog(@"%s, doesn't have audio.", __func__);
			return;
		}
		if (self._player == nil) {
			[self playLink:audioLink];	
		}
		else if (currentPlayedPage != currentSelectedPage) {
			// different page, 
			[self playLink:audioLink];
		}
		else if (self._player && self._player.playing == NO) {
			[self._audioButton setBackgroundImage:self._audioStopButton forState:UIControlStateNormal];
			[self._player play];
		}
		else {
			// stop the audio
			[self._audioButton setBackgroundImage:self._audioPlayButton forState:UIControlStateNormal];
			[self._player pause];
		}
	}
}

- (void)showNextImage:(NSTimer*)timer
{
	
	if (++currentSlideshowPage < numberOfPages) {
		[self showContentOfIndex:currentSlideshowPage];
		[self.currentSlideImageController reDrawWithJournal:[self getJournalForPage:currentSlideshowPage]];
	}
	else {
		[self._playButton setBackgroundImage:self._bigPlayButton forState:UIControlStateNormal];
		[timer invalidate];
		isSlideShowRunning = NO;
		[UIApplication sharedApplication].idleTimerDisabled = NO;
	}
	
	
}

- (void)stopSlideShow:(id)sender
{
	[self._playButton setBackgroundImage:self._bigPlayButton forState:UIControlStateNormal];
	isSlideShowRunning = NO;
	if (self.slideShowTimer != nil) {
		[self.slideShowTimer invalidate];
	}
}

- (IBAction)playSlideshow:(id)sender
{
	if (isSlideShowRunning == NO) {
		[self._playButton setBackgroundImage:self._bigStopButton forState:UIControlStateNormal];
		[UIApplication sharedApplication].idleTimerDisabled = YES;
		self.currentSlideImageController = [self getImageControllerWithPage:currentSelectedPage];
		if (self.currentSlideImageController == nil) {
			NSLog(@"%s, target is null: %d", __func__, currentSelectedPage);
			return;
		}
		currentSlideshowPage = 0;

		// TODO: Need to remove timer at some point.
		NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop]; 
		// Create and schedule the first timer. 
		NSDate* futureDate = [NSDate dateWithTimeIntervalSinceNow:DEFAULT_SLIDER_VALUE]; 
		NSTimer *timer = [[NSTimer alloc] initWithFireDate:futureDate 
												interval:self._slider.value
												target:self
												selector:@selector(showNextImage:) 
												userInfo:nil 
												repeats:YES]; 
		[myRunLoop addTimer:timer forMode:NSDefaultRunLoopMode]; 
		self.slideShowTimer = timer; 
		[timer release];
		isSlideShowRunning = YES;
	}
	else {
		[self._playButton setBackgroundImage:self._bigPlayButton forState:UIControlStateNormal];
		[self.slideShowTimer invalidate];
		isSlideShowRunning = NO;
		[UIApplication sharedApplication].idleTimerDisabled = NO;
	}
	
}

#pragma mark -

#pragma mark AVAudioPlayer Delegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	[self._audioButton setBackgroundImage:self._audioPlayButton forState:UIControlStateNormal];
}


#pragma mark -
#pragma mark IMAGE SLIDER SETTING

- (UIButton*)getInfoButton
{
	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
	infoButton.frame = CGRectMake(INFO_BUTTON_X, INFO_BUTTON_Y, INFO_BUTTON_WIDTH, INFO_BUTTON_HEIGHT);
	[infoButton addTarget:self action:@selector(goSetting:) forControlEvents:UIControlEventTouchDown];
	infoButton.showsTouchWhenHighlighted = YES;
	return infoButton;
}

- (void)slideSettingDone:(id)sender
{
	//HorizontalImageViewController *controller = nil;
	BOOL refresh = NO;
	self.navigationItem.title = @"Slideshow";
	UIBarButtonItem *playBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playSlideShow:)];
	self.navigationItem.rightBarButtonItem = playBarButton;
	[playBarButton release];
	self.navigationItem.leftBarButtonItem = nil;
	// TODO: Apply new settings
	//if ([[GeoDefaults sharedGeoDefaultsInstance].categoryTypeForHorizontal intValue] != self._categoryType.selectedSegmentIndex) {
	//	refresh = YES;
	//}
	
	[GeoDefaults sharedGeoDefaultsInstance].showSlideshowInHorizontal = [NSNumber numberWithBool:self._showSlideShow.on];
	[GeoDefaults sharedGeoDefaultsInstance].enableAudioInHorizontal = [NSNumber numberWithBool:self._enableAudio.on];
	[GeoDefaults sharedGeoDefaultsInstance].showContentInHorizontal = [NSNumber numberWithBool:self._showContent.on];
	[GeoDefaults sharedGeoDefaultsInstance].sliderForHorizontal = [NSNumber numberWithInt:self._slider.value];
	[[GeoDefaults sharedGeoDefaultsInstance] saveHorizontalSlideshowSettings];
	// ---
	if (refresh == YES) {
		currentPage = -1;
		currentSelectedPage = 0;
		currentArrayPointer = 0;
		numberOfPages = [self setPagesForSlideShow];
		// TODO: refresh pictures when pictures are changed. 
		_scrollView.contentOffset = CGPointMake(0.0, 0.0);
		_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * numberOfPages, SCROLL_VIEW_HEIGHT);
		[self viewDidAppear:NO];
	}
	
	if (contentShown && self._showContent.on == NO) {
		// remove it from superview
		self._contentView.hidden = YES;
		//controller = [self getImageControllerWithPage:currentSelectedPage];
		//[controller._sliderView removeFromSuperview];
	}
	else if (contentShown == NO && self._showContent.on == YES) {
		// add it to subview
		self._contentView.hidden = NO;
		//controller = [self getImageControllerWithPage:currentSelectedPage];
		//[controller._imageView addSubview:controller._sliderView];
	}
	
	if (audioShown && self._enableAudio.on == NO) {
		// remove it from superview
		[self._audioButtonView removeFromSuperview];
	}
	else if (audioShown == NO && self._enableAudio.on == YES) {
		// add it to subview
		[self.view addSubview:self._audioButtonView];
	}
	
	if (playShown && self._showSlideShow.on == NO) {
		// remove it from superview
		[self._playButtonView removeFromSuperview];
	}
	else if (playShown == NO && self._showSlideShow.on == YES) {
		// add it to subview.
		[self.view addSubview:self._playButtonView];
	}
	
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationTransition: UIViewAnimationTransitionCurlDown forView:self.view cache:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];
	self.navigationController.navigationBarHidden = YES;
	// Animations
	//[self.view exchangeSubviewAtIndex:1 withSubviewAtIndex:0];
	[self._settingView removeFromSuperview];
	[self.currentSlideImageController.view addSubview:self.currentSlideImageController._imageView];
	
	// Commit Animation Block
	[UIView commitAnimations];
	
}

- (IBAction)goSetting:(id)sender
{
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(slideSettingDone:)];
	
	self.navigationItem.leftBarButtonItem = button;
	[button release];
	self.navigationItem.rightBarButtonItem = nil;
	self.navigationItem.title = @"Slideshow Setting";
	
	self._showSlideShow.on = [[GeoDefaults sharedGeoDefaultsInstance].showSlideshowInHorizontal boolValue];
	self._enableAudio.on = [[GeoDefaults sharedGeoDefaultsInstance].enableAudioInHorizontal boolValue];
	self._showContent.on = [[GeoDefaults sharedGeoDefaultsInstance].showContentInHorizontal boolValue];
	self._slider.value = [[GeoDefaults sharedGeoDefaultsInstance].sliderForHorizontal intValue];
	self._defaultCategory.text = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
	
	contentShown = self._showContent.on;
	audioShown = self._enableAudio.on;
	playShown = self._showSlideShow.on;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationTransition: UIViewAnimationTransitionCurlUp forView:self.view cache:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];
	
	self._settingView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	// Animations
	//[self.view exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
	self.currentSlideImageController = [self getImageControllerWithPage:currentSelectedPage];
	[self.currentSlideImageController._imageView removeFromSuperview];
	[self.view addSubview:self._settingView];
	self.navigationController.navigationBarHidden = NO;
	// Commit Animation Block
	[UIView commitAnimations];
	
}

#pragma mark -

#pragma mark SCROLLVIEW DELEGATE

- (void)scrollViewDidScroll:(UIScrollView *)sender 
{
    // Switch the indicator when more than 50% of the previous/next page is visible
	if (isSlideShowRunning == YES) {
		[self stopSlideShow:nil];
	}
    CGFloat pageWidth = _scrollView.frame.size.width;
    int page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
	if (page == 0) {
		// special case.
	}
	else if (page ==  currentPage) {
		TRACE("---> %s: next page: %d, cur: %d\n", __func__, page, currentPage);
		// Page is increasing, we just need to get the next page
		++currentPage;
		[self loadImageView:currentPage];
		//[self cleanController:currentPage-2];
		
	}
	else if (page+2 == currentPage) {
		TRACE("---> %s: previous page: %d, cur: %d\n", __func__, page, currentPage);
		// Page is decreasing, we just need to get the previous page
		if (currentPage > 0)
			--currentPage;
		[self loadImageView:page-1];
		//[self cleanController:currentPage+2];
		
	}
	
	currentSelectedPage = page;
	[self showContentOfIndex:currentSelectedPage];
	//TRACE("%s, page: %d\n", __func__, page);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	//toolBar.hidden = YES;
	//self.navigationController.navigationBarHidden = YES;
	//navigationBar.hidden = YES;
}

- (HorizontalImageViewController*)getImageControllerWithPage:(NSInteger)page
{
	HorizontalImageViewController* controller = nil;
	
	for (HorizontalPageViewControllerPointer* ptr in controllerArray) {
		if (ptr.page != -1 && ptr.page == page) {
			controller = ptr.controller;
			break;
		}
	}
	
	return controller;
}


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

- (void)viewWillDisappear:(BOOL)animated
{
	[self stopSlideShow:nil];
}

- (void)viewDidUnload {
	TRACE_HERE;
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self._imageView = nil;
	self._scrollView = nil;
	self._showSlideShow = nil;
	self._enableAudio = nil;
	self._showContent = nil;
	self._settingView = nil;
	self._audioButtonView = nil;
	self._playButtonView = nil;
	self._audioButton = nil;
	self._playButton = nil;
	self._slider = nil;
	self._contentView = nil;
	self.articleDescription = nil;
	self.articleTitle = nil;
	self.controllerArray = nil;
	self._defaultCategory = nil;
	
	self._audioStopButton = nil;
	self._audioPlayButton = nil; 
	self._bigStopButton = nil;
	self._bigPlayButton = nil;
	self._audioNoAvailButton = nil;
}


- (void)dealloc {
	TRACE_HERE;
	[_audioNoAvailButton release];
	[articleDescription release];
	[articleTitle release];
	[_contentView release];
	[_bigStopButton release];
	[_slider release];
	[_audioPlayButton release];
	[_bigPlayButton release];
	[_player release];
	[_audioStopButton release];
	[_audioButton release];
	[_playButton release];
	[_audioButtonView release];
	[_playButtonView release];
	[_settingView release];
	[_showSlideShow release];
	[_enableAudio release];
	[_showContent release];
	[_imageView release];
	[_scrollView release];
	[categoryArray release];
	[controllerArray release];
	[journalArray release];
	[slideShowTimer invalidate];
	[slideShowTimer release];
	[currentSlideImageController release];
	[_defaultCategory release];
	
    [super dealloc];
}


@end
