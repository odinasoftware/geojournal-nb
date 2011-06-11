    //
//  ImageArrayScrollController.m
//  JeJuSite
//
//  Created by Jae Han on 8/21/10.
//  Copyright 2010 Home. All rights reserved.
//
#include <pthread.h>
#import <QuartzCore/QuartzCore.h>

//#import "OdinaCommon.h"
#import "GeoJournalHeaders.h"
//#import "RequestOperation.h"
#import "ImageContainer.h"
#import "ImageArrayScrollController.h"
#import "SlideImageView.h"
#import "GeoDefaults.h"

#define SCROLL_VIEW_IMAGE_X			2.0
#define SCROLL_VIEW_IMAGE_Y			2.0
#define SCROLL_VIEW_IMAGE_WIDTH		56.0
#define SCROLL_VIEW_IMAGE_HEIGHT	56.0
#define IMAGE_MARGIN				5.0
#define BACKGROUND_MARGIN			1.0

extern NSString *getThumbnailFilename(NSString *filename);
extern NSString *getThumbnailOldFilename(NSString *filename);

float getDistance(CGPoint first, CGPoint second)
{
	return sqrt(pow((first.x - second.x), 2.0) + pow((first.y - second.y), 2.0));
}

void *display_images_in_thread(void* arg)
{
	pthread_detach(pthread_self());
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	ImageArrayScrollController *controller = (ImageArrayScrollController*)arg;
	
	ImageContainer *container = nil;
	UIImage *tmp = nil;
	int i = 0;
	
	for (NSString *img_url in controller.imageArray) {
		container = [controller.imageContainerArray objectAtIndex:i]; ++i;
		if (container) {
			[container.activity stopAnimating];
			NSString *abs_path = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:img_url];
			NSString *thumb = getThumbnailFilename(abs_path);
			if ([[NSFileManager defaultManager] fileExistsAtPath:thumb] == NO) {
				[thumb release];
				thumb = getThumbnailOldFilename(abs_path);
			}
			
			//tmp = [[UIImage alloc] initWithContentsOfFile:thumbStr];
			//container.image = tmp; [tmp release];
			//tmp = [[UIImage alloc] initWithCGImage:container.image.CGImage scale:THUMBNAIL_RATIO orientation:UIImageOrientationUp];		
			TRACE("%s, %s\n", __func__, [thumb UTF8String]);
			
			tmp = [[UIImage alloc] initWithContentsOfFile:thumb];
			container.imageView.image = tmp; [tmp release];
			[thumb release];
		}
	}
	
	
	[pool release];
	
	return nil;
}	
@implementation ImageArrayScrollController

@synthesize scrollView;
@synthesize imageArray;
@synthesize imageContainerArray = _imageContainerArray;
@synthesize firstPicturename;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	_imageContainerArray = [[NSMutableArray alloc] initWithCapacity:5];
	
	self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height+20);
	DEBUG_RECT("ImageArray", self.scrollView.frame);
	self.scrollView.delegate = self;
	self.view.userInteractionEnabled = YES;
	self.scrollView.userInteractionEnabled = YES;
	[self.scrollView setDelegate:self];
	_selectedIndex = 0;
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)cleanPreviousViews
{
	for (ImageContainer *c in self.imageContainerArray) {
		[c.selectionRectangle removeFromSuperview];
	}
}

- (void)displayImages
{
	ImageContainer *container = nil;
	UIImage *tmp = nil;
	int i = 0;
	
	for (NSString *img_url in self.imageArray) {
		container = [self.imageContainerArray objectAtIndex:i]; ++i;
		if (container) {
			[container.activity stopAnimating];
			NSString *abs_path = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:img_url];
			NSString *thumb = getThumbnailFilename(abs_path);
			if ([[NSFileManager defaultManager] fileExistsAtPath:[[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:thumb]] == NO) {
				[thumb release];
				thumb = getThumbnailOldFilename(abs_path);
			}
			
			//tmp = [[UIImage alloc] initWithContentsOfFile:thumbStr];
			//container.image = tmp; [tmp release];
			//tmp = [[UIImage alloc] initWithCGImage:container.image.CGImage scale:THUMBNAIL_RATIO orientation:UIImageOrientationUp];		
			TRACE("%s, %s\n", __func__, [thumb UTF8String]);
			[thumb release];
			tmp = [[UIImage alloc] initWithContentsOfFile:abs_path];
			container.imageView.image = tmp; [tmp release];
		}
	}
}

- (void)startLoadingImages
{
	ImageContainer *container = nil;
	UIImageView *imageView = nil;
	UIActivityIndicatorView *activityView = nil;
	UIView *backView = nil;
	float x = SCROLL_VIEW_IMAGE_X;
	int i = 0;
	self.scrollView.contentSize = CGSizeMake((SCROLL_VIEW_IMAGE_WIDTH+IMAGE_MARGIN)*[self.imageArray count], SCROLL_VIEW_IMAGE_HEIGHT);
	//self.scrollView.showsVerticalScrollIndicator = NO;
	float d = getDistance(CGPointMake(SCROLL_VIEW_IMAGE_X, SCROLL_VIEW_IMAGE_Y), CGPointMake(SCROLL_VIEW_IMAGE_X-BACKGROUND_MARGIN, SCROLL_VIEW_IMAGE_Y-BACKGROUND_MARGIN));
	
	TRACE("%s, distance: %f, count: %d\n", __func__, d, [self.imageArray count]);
	
	@try {
		for (NSString *img_url in self.imageArray) {
			TRACE("%s, Image: %s\n", __func__, [img_url UTF8String]);
			if ([self.imageContainerArray count] > i) {
				container = [self.imageContainerArray objectAtIndex:i];
				
				backView = container.selectionRectangle;
			}
			else {
				container = [[ImageContainer alloc] init];
				imageView = [[UIImageView alloc] initWithFrame:CGRectMake(SCROLL_VIEW_IMAGE_X, SCROLL_VIEW_IMAGE_Y, SCROLL_VIEW_IMAGE_WIDTH, SCROLL_VIEW_IMAGE_HEIGHT)];
				imageView.multipleTouchEnabled = YES;
				imageView.backgroundColor = [UIColor blackColor];
				imageView.contentMode = UIViewContentModeScaleToFill;
				//imageView.opaque = NO;
				//imageView.userInteractionEnabled = NO;	
				activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
				
				container.imageView = imageView; 
				activityView.frame = CENTER_RECT(activityView.frame, imageView.frame);
				container.activity = activityView;
				
				[imageView addSubview:activityView];
				[activityView startAnimating];
				[self.imageContainerArray addObject:container];
				
				backView = [[UIView alloc] initWithFrame:CGRectMake(x-BACKGROUND_MARGIN, SCROLL_VIEW_IMAGE_Y-BACKGROUND_MARGIN, SCROLL_VIEW_IMAGE_WIDTH+(BACKGROUND_MARGIN*4), SCROLL_VIEW_IMAGE_HEIGHT+(BACKGROUND_MARGIN*4))];
				CALayer *layer = [backView layer];
				layer.cornerRadius = 0.5f;
				backView.multipleTouchEnabled = NO;
				backView.userInteractionEnabled = NO;
				
				//DEBUG_RECT("Image view:", imageView.frame);
				//DEBUG_RECT("back view:", backView.frame);
				//backView.opaque = NO;
				[backView addSubview:imageView];
				container.selectionRectangle = backView;
				container.selectionRectangle.tag = i+1;
				
				// Add to scroll view
				//[self.scrollView addSubview:imageView];
				
				[backView release];
				//[url release];
				[container release];
				[imageView release];
				[activityView release];
			}
			
			if (i == 0) {
				backView.backgroundColor = [UIColor whiteColor];
			}
			else {
				backView.backgroundColor = [UIColor clearColor];
			}
		
			UIView *inner = [self.scrollView viewWithTag:i+1];
			if (inner == nil) {
				[self.scrollView addSubview:container.selectionRectangle];
			}
			//NSURL *url = [[NSURL alloc] initWithString:img_url];
			//RequestOperation *operation = [[RequestOperation alloc] initWithURL:url delegate:nil withContainer:container forType:GET_IMAGE];
			//[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(addOperation:) withObject:operation waitUntilDone:NO];
						//DEBUG_SIZE("container orig:", container.image.size);
			//DEBUG_SIZE("container thumb:", container.imageView.image.size);
			
			++i;
			x = x+SCROLL_VIEW_IMAGE_WIDTH + IMAGE_MARGIN;
		}
		
		if (i < [self.imageContainerArray count]) {
			// has to be taken out from the superview.
			for (int j=i; j<[self.imageContainerArray count]; ++j) {
				UIView *inner = [self.scrollView viewWithTag:j+1];
				[inner removeFromSuperview];
			}
		}
		
		// This doesn't look like running in separate thread at all.
		pthread_t thread;
		
		pthread_create(&thread, nil, (void*)(display_images_in_thread), (void*)self);
		
		//[self performSelectorOnMainThread:@selector(displayImages) withObject:nil waitUntilDone:NO];
		// This is different but it may not have context. 
		//[self performSelectorInBackground:@selector(displayImages) withObject:nil];
	}
	@catch (NSException * e) {
		NSLog(@"%s, %@", __func__, e);
	}
	@finally {

	}
	
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollViewIn
{
	TRACE("%s, offset: x: %f, y: %f\n", __func__, scrollViewIn.contentOffset.x, scrollViewIn.contentOffset.y);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s, \n", __func__);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s, \n", __func__);
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s, \n", __func__);
}

#pragma mark -

- (NSInteger)findImgIndex:(CGPoint)point
{
	float size = scrollView.contentSize.width;

	if (point.x > size) {
		TRACE("%s, outside of view: %f\n", __func__, point.x);
		return 0;
	}
	NSInteger index = point.x / (SCROLL_VIEW_IMAGE_WIDTH + IMAGE_MARGIN);
	
	TRACE("%s, index: %d\n", __func__, index);
	return index;
}

- (NSString*)getSelectedImageName
{
	NSString *s = nil;
	
	if (_selectedIndex == 0) {
		s = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.firstPicturename];
	}
	else {
		s = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:[self.imageArray objectAtIndex:_selectedIndex]];
	}

	return s;
}
#pragma mark SlideImageViewDelegate

- (void)selectImage:(CGPoint)point
{
	//UIImage *mainView = nil;
	NSString *filePath = nil;
	
	NSInteger imgIndex = [self findImgIndex:point];
	ImageContainer *container = [self.imageContainerArray objectAtIndex:imgIndex];
	container.selectionRectangle.backgroundColor = [UIColor whiteColor];
	if (imgIndex == 0) {
		filePath = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:self.firstPicturename];
		//mainView = [[UIImage alloc] initWithContentsOfFile:filePath];
	}
	else {
		filePath = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:[self.imageArray objectAtIndex:imgIndex]];
		//mainView = [[UIImage alloc] initWithContentsOfFile:filePath];
	}
	_selectedIndex = imgIndex;
	TRACE("%s, x: %f, y: %f, index: %d, %s\n", __func__, point.x, point.y, imgIndex, [filePath UTF8String]);

	//[mainView release];
	
	for (int i=0; i<[self.imageContainerArray count]; ++i) {
		if (i != imgIndex) {
			container = [self.imageContainerArray objectAtIndex:i];
			container.selectionRectangle.backgroundColor = [UIColor clearColor];
		}
	}
	
}
#pragma mark -
#pragma mark IMAGE 
- (void)addImage:(UIImage*)image
{
	ImageContainer *container = [[ImageContainer alloc] init];

	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(SCROLL_VIEW_IMAGE_X, SCROLL_VIEW_IMAGE_Y, SCROLL_VIEW_IMAGE_WIDTH, SCROLL_VIEW_IMAGE_HEIGHT)];
	imageView.multipleTouchEnabled = YES;
	UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	//DEBUG_RECT("ImageView:", imageView.frame);
	imageView.backgroundColor = [UIColor blackColor];
	imageView.contentMode = UIViewContentModeScaleToFill;
	//imageView.opaque = NO;
	//imageView.userInteractionEnabled = NO;
	imageView.image = image;
	container.imageView = imageView; 
	activityView.frame = CENTER_RECT(activityView.frame, imageView.frame);
	container.activity = activityView;
	
	[imageView addSubview:activityView];
	[activityView startAnimating];
	[self.imageContainerArray addObject:container];
	[container release];
	
}
#pragma mark -

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.scrollView = nil;
}


- (void)dealloc {
	TRACE_HERE;
	[imageArray release];
	[_imageContainerArray release];
    [super dealloc];
}


@end
