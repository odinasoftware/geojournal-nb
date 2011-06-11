//
//  SlideShowViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/20/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "SlideShowViewController.h"
#import "GeoDatabase.h"
#import "Category.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "GeoDefaults.h"
#import "ImageViewController.h"
#import "JournalEntryViewController.h"
#import "ArticleScrollView.h"

#define SCROLL_VIEW_HEIGHT			365.0
#define MAX_CONTROLLER_NUM			3
#define reflectionFraction			0.35
#define reflectionOpacity			0.5
#define INITIAL_SLIDE_IMAGE			3
#define DEFAULT_NUMBER_OF_PAGES		20
#define DEFAULT_SLIDER_VALUE		3

#define INFO_BUTTON_X				280.0
#define INFO_BUTTON_Y				320.0

extern int getNumberFromIndex(int i);

@implementation PageViewControllerPointer

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
	TRACE_HERE;
	[controller release];
	[super dealloc];
}

@end


@implementation SlideShowViewController

@synthesize _category;
@synthesize _scrollView;
@synthesize categoryArray;
@synthesize journalArray;
@synthesize slideShowTimer;
@synthesize currentSlideImageController;
@synthesize controllerArray;
@synthesize _journalView;
@synthesize _titleLabel;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (NSInteger)setPagesForSlideShow
{
	NSArray *array = nil;
	NSInteger pages = -1;
	
	pages = -1; //getNumberFromIndex([[GeoDefaults sharedGeoDefaultsInstance].imageNumLocation intValue]); //DEFAULT_NUMBER_OF_PAGES;
	
	TRACE("%s, %d\n", __func__, pages);
	
	for (Category *c in categoryArray) {
		if ([c.name compare:[GeoDefaults sharedGeoDefaultsInstance].activeCategory] == NSOrderedSame) {
			array = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:c];
		}
	}
		
	self.journalArray = array;	
	numberOfPages = [journalArray count];
	return numberOfPages;
}

- (NSArray*)getPageControllerArray
{
	NSArray *a = nil;
	
	PageViewControllerPointer *p1 = [[PageViewControllerPointer alloc] initWithPage:-1];
	PageViewControllerPointer *p2 = [[PageViewControllerPointer alloc] initWithPage:-1];
	PageViewControllerPointer *p3 = [[PageViewControllerPointer alloc] initWithPage:-1];
	
	a = [[NSArray alloc] initWithObjects:p1, p2, p3, nil];
	[p1 release]; [p2 release]; [p3 release];

	return a;
}

- (UIView*)getTitleView
{
#define	START_Y	10.0
	
	UIView *textView = [[UIView alloc] initWithFrame:CGRectMake(0.0, START_Y, 100.0, 50.0)];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, START_Y, 100.0, 20.0)];
	
	label.text = @"Slideshow";
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
/* VidwDidLoad and ViewDidAppear
 *   The "ViewDidAppear" can be executed when the view reappear from some other view. 
 *   Therefore it is not necessary to reload array all the time. 
 *   But also there may be some case that the array needs to be reload, specailly after adding a new journal.
 *
 *   Questions:
 *		1. How to differentiate between restoring view or initial view or reappearing without change or 
 *			reappearing with view change.
 *		2. When the view reappears, how to handle the previous view.
 *
 *   Cases:
 *      1. When it stars from a new category.
 *		2. Change category to entire
 *		3. Change category from Journal view.
 */
- (void)viewDidLoad {
    [super viewDidLoad];
	
	TRACE_HERE;
	UIView *titleView = [self getTitleView];
	self.navigationItem.titleView = titleView;
	[titleView release];
	
	currentPage = -1;
	currentSelectedPage = 0;
	currentArrayPointer = 0;
	_category = nil;
	
	UIBarButtonItem *playBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playSlideShow:)];
	//UIBarButtonItem *stopBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(stopSlideShow:)];
	
	
	NSArray *array = [self getPageControllerArray]; 
	self.controllerArray = array;
	[array release];
	
	self.navigationItem.rightBarButtonItem = playBarButton;
	[playBarButton release];
	
	self.view.backgroundColor = [UIColor blackColor];
	
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
	TRACE("%s, w: %f, h: %f\n", __func__, _scrollView.contentSize.width, _scrollView.contentSize.height);
	
	self.tabBarController.tabBar.selectedItem.title = @"Slideshow";
	currentSelectedPage = 0;
	isSlideShowRunning = NO;
	self._scrollView.responder = self;
}

/* Taking care of three different cases:
 *   case 1: When view is restored.
 *   case 2: When view is appared first.
 *   case 3: When view is reappeared, don't need to load any view.
 *   case 4: When view needs to be reloaded.
 */
- (void)viewDidAppear:(BOOL)animated
{
	TRACE_HERE;
	
	if ([GeoDefaults sharedGeoDefaultsInstance].levelRestored == NO) {
		// case 1
		[self restoreLevel];
		self._category = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
	}
	else {
		if (self._category == nil) { 
			// case 2
			[self refreshView];
			self._category = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
		}
		else if ([[GeoDefaults sharedGeoDefaultsInstance] needRefreshCategory:self._category]) {
			// need to reload view, case 4
			[self resetView];
			[self refreshView];
			self._category = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
			self._titleLabel.text = self._category;
		}
		
		
		[GeoDefaults sharedGeoDefaultsInstance].secondLevel = -1;
	}
}

- (void)resetView
{
	currentPage = -1;
	currentSelectedPage = 0;
	currentArrayPointer = 0;
	
	numberOfPages = [self setPagesForSlideShow];
	
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * numberOfPages, SCROLL_VIEW_HEIGHT);	
	_scrollView.contentOffset = CGPointMake(0.0, 0.0);
}

- (void)refreshView
{
	//numberOfPages = [self setPagesForSlideShow];
	
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * numberOfPages, SCROLL_VIEW_HEIGHT);
	
	if (numberOfPages == 0) {
		[self loadImageView:0];
	}
	else {
		int i = 0;
		for (i=0; i<(currentSelectedPage>0?currentSelectedPage-1:0)+INITIAL_SLIDE_IMAGE; ++i) {
			[self loadImageView:i];
		}
		
		currentPage = i - 1; // represent the last loaded page
	}
	currentSelectedPage = 0;
}

- (CGRect)getRectFromPage:(int)page
{
	CGFloat pageWidth = _scrollView.frame.size.width;
	CGRect rect = CGRectMake(pageWidth*page, 0.0, pageWidth, _scrollView.contentSize.height);
	TRACE("%s, %d\n", __func__, page);
	DEBUG_RECT("restore", rect);
	return rect;
}

- (void)restoreLevel
{
	// TODO: show the last page
	int index = [GeoDefaults sharedGeoDefaultsInstance].secondLevel;
	int index3 = [GeoDefaults sharedGeoDefaultsInstance].thirdLevel;
	
	if (index > -1) {
		TRACE("%s, index: %d\n", __func__, index);
		if (numberOfPages == 0) {
			[self loadImageView:0];
		}
		else {
			int i = 0;
			for (i=index; i<index+INITIAL_SLIDE_IMAGE; ++i) {
				[self loadImageView:i];
			}
			
			currentPage = i - 1; // represent the last loaded page
			
			[self._scrollView scrollRectToVisible:[self getRectFromPage:index] animated:NO];
			//self._scrollView.contentOffset = CGPointMake(self._scrollView.frame.size.width * index, 0.0);
			[self scrollViewDidScroll:self._scrollView];
			if (index3 > -1) {
				TRACE("%s\n", __func__);
				JournalEntryViewController *controller = [[JournalEntryViewController alloc] initWithNibName:@"JournalEntryView" bundle:nil];
				controller.entryForThisView = [journalArray objectAtIndex:index];
				controller.hidesBottomBarWhenPushed = YES;
				[self.navigationController pushViewController:controller animated:NO];
				self._journalView = controller;
				[controller release];			
			}
		}
	}
	else {
		[self refreshView];
	}

	[GeoDefaults sharedGeoDefaultsInstance].levelRestored = YES;
	
}

#pragma mark SLIDER EVENT
- (void)showImageControls:(int)tapCount
{	
	if (isSlideShowRunning == NO && tapCount == 2) {
		// Open Journal Entry View
		JournalEntryViewController *controller = [[JournalEntryViewController alloc] initWithNibName:@"JournalEntryView" bundle:nil];
		controller.showToolbar = NO;
		controller.entryForThisView = [self getJournalForPage:currentSelectedPage];
		controller.hidesBottomBarWhenPushed = YES;
		[GeoDefaults sharedGeoDefaultsInstance].thirdLevel = currentSelectedPage;
		[self.navigationController pushViewController:controller animated:YES];
		self._journalView = controller;
		[controller release];
		
	}
	else if (isSlideShowRunning == YES && tapCount > 0) {
		[self stopSlideShow:nil];
	}
	
}

#pragma mark -

- (Journal*)getJournalForPage:(NSInteger)page
{
	Journal *j = nil;
	if (page < [journalArray count]) {
		j = [journalArray objectAtIndex:page];
	}
	return j;
}

- (ImageViewController*)getNextImageViewControllerWithPage:(NSInteger)page needRedraw:(BOOL*)redraw
{
	int target = -1;
	
	TRACE("%s, cur: %d, page: %d\n", __func__, currentPage, page);
	
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
	
	PageViewControllerPointer *pointer = [controllerArray objectAtIndex:target];
	if (pointer.controller == nil) {
		ImageViewController *c = [[ImageViewController alloc] initWithNibName:@"ImageView" withJournal:[self getJournalForPage:page]];
		pointer.controller = c;
		[c release];
		pointer.controller.view.tag = page;
		*redraw = NO;
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
	
	ImageViewController *controller = [self getNextImageViewControllerWithPage:page needRedraw:&shouldRedraw];
	
	//[self.view addSubview:[self getInfoButton]];
	CGRect frame = _scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
	controller.view.frame = frame;
	
	if (shouldRedraw == NO) {
		
		[_scrollView addSubview:controller.view];
		//[self addToControllerArray:controller withPage:page forLink:controller.webLink];
	}
	else {
		
		[controller reDrawWithJournal:[self getJournalForPage:page]];
		
		[_scrollView addSubview:controller.view];
	}
	TRACE("%s, c: %f, y: %f\n", __func__, frame.origin.x, frame.origin.y);
}

#pragma mark SLIDESHOW Delegate

- (ImageViewController*)getImageControllerWithPage:(NSInteger)page
{
	ImageViewController* controller = nil;
	
	for (PageViewControllerPointer* ptr in controllerArray) {
		if (ptr.page != -1 && ptr.page == page) {
			controller = ptr.controller;
			break;
		}
	}
	
	return controller;
}

- (void)showNextImage:(NSTimer*)timer
{
	if (self.currentSlideImageController.sliderBeingUsed == NO && self.currentSlideImageController.sliderHidden == NO) {
		if ([[GeoDefaults sharedGeoDefaultsInstance].showImageSlider boolValue] == YES)
			[self.currentSlideImageController hideSliderSetting];
	}
	else if (self.currentSlideImageController.sliderBeingUsed == NO) {
		if (++currentSlideshowPage < numberOfPages) {
			[self.currentSlideImageController reDrawWithJournal:[self getJournalForPage:currentSlideshowPage]];
		}
		else {
			UIBarButtonItem *playBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playSlideShow:)];
			self.navigationItem.rightBarButtonItem = playBarButton;
			[playBarButton release];
			
			[timer invalidate];
			isSlideShowRunning = NO;
		}
	}
	
}

- (void)stopSlideShow:(id)sender
{
	UIBarButtonItem *playBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playSlideShow:)];
	self.navigationItem.rightBarButtonItem = playBarButton;
	[playBarButton release];
	isSlideShowRunning = NO;
	if (self.slideShowTimer != nil) {
		[self.slideShowTimer invalidate];
	}
}

- (void)playSlideShow:(id)sender
{
	UIBarButtonItem *stopBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(stopSlideShow:)];
	self.navigationItem.rightBarButtonItem = stopBarButton;
	[stopBarButton release];
	
	self.currentSlideImageController = [self getImageControllerWithPage:currentSelectedPage];
	if (self.currentSlideImageController == nil) {
		NSLog(@"%s, target is null: %d", __func__, currentSelectedPage);
		return;
	}
	currentSlideshowPage = 0;
	if ([[GeoDefaults sharedGeoDefaultsInstance].showImageSlider boolValue] == YES)
		[self.currentSlideImageController showSliderSetting];
	//toolBar.hidden = YES;
	// TODO: Need to remove timer at some point.
	NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop]; 
	// Create and schedule the first timer. 
	NSDate* futureDate = [NSDate dateWithTimeIntervalSinceNow:DEFAULT_SLIDER_VALUE]; 
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:futureDate 
											interval:self.currentSlideImageController._slider.value
											target:self
											selector:@selector(showNextImage:) 
											userInfo:nil 
											repeats:YES]; 
	[myRunLoop addTimer:timer forMode:NSDefaultRunLoopMode]; 
	self.slideShowTimer = timer; 
	[timer release];
	isSlideShowRunning = YES;
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
	
	// TODO: is this good idea???
	[GeoDefaults sharedGeoDefaultsInstance].secondLevel = currentSelectedPage;
	//TRACE("%s, page: %d\n", __func__, page);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	//toolBar.hidden = YES;
	//self.navigationController.navigationBarHidden = YES;
	//navigationBar.hidden = YES;
}


#pragma mark -
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	TRACE_HERE;
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
	self._scrollView = nil;
	self._category = nil;
	self.controllerArray = nil;
	self._journalView = nil;
}


- (void)dealloc {
	[_titleLabel release];
	[_journalView release];
	[_category release];
	[_scrollView release];
	[categoryArray release];
	[journalArray release];
	[slideShowTimer release];
	[currentSlideImageController release];
	[controllerArray release];
	
    [super dealloc];
}


@end
