//
//  FullImageViewController.m
//  GeoJournal
//
//  Created by Jae Han on 10/2/10.
//  Copyright 2010 Home. All rights reserved.
//
#include <pthread.h>

#import "GeoJournalHeaders.h"
#import "FullImageViewController.h"
#import "JournalEntryViewController.h"
#import "GeoDatabase.h"
#import "Journal.h"
#import "GeoDefaults.h"
#import "Pictures.h"
#import "JournalViewController.h"

#define ZOOM_STEP 1.5

void *display_image_in_thread(void *arg)
{
	pthread_detach(pthread_self());
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	image_holder *holder = (image_holder*) arg;
	UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPathWithUUID:holder->file_name]];
	holder->imageView.image = image;
	[image release];
	if (holder->activityView) {
		[holder->activityView stopAnimating];
		[holder->activityView removeFromSuperview];
	}
	
	free(holder);
	[pool release];
	
	return nil;
}

@implementation FullImageViewController

@synthesize imageView;
@synthesize parent;
@synthesize imageScrollView;
@synthesize pictures;
@synthesize trashButton;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	TRACE_HERE;
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	self.imageView.image = nil; //self.parent.imageForJournal.image;
	self.parent.imageForJournal.image = nil;
	//[self.parent.imageForJournal release];
	
	UISwipeGestureRecognizer *rightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(performRightSwipe:)];
	UISwipeGestureRecognizer *leftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(performLeftSwipe:)];
	leftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
	_swipe_loc = -1;
	
	[self.imageView addGestureRecognizer:rightRecognizer];
	[self.imageView addGestureRecognizer:leftRecognizer];
	
	self.pictures = [[GeoDatabase sharedGeoDatabaseInstance] picturesForJournal:self.parent.entryForThisView.picture];
	//self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	//self.navigationController.navigationBar.hidden = YES;
	TRACE("%s, %p\n", __func__, self.imageView.image);
	[rightRecognizer release];
	[leftRecognizer release];
	
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeThisPicture:)];
	self.trashButton = button;
	self.navigationItem.rightBarButtonItem = self.trashButton;
	[button release];
	
	UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	activityView.frame = CENTER_RECT(activityView.frame, self.imageView.frame);
	[self.imageView addSubview:activityView];
	[activityView startAnimating];
	[activityView release];
	
	pthread_t thread;
	image_holder *holder = (image_holder*) malloc(sizeof(image_holder));
	self.imageView.image = nil;
	holder->imageView = self.imageView;
	holder->file_name = self.parent.entryForThisView.picture;
	holder->activityView = activityView;
	pthread_create(&thread, nil, (void*)(display_image_in_thread), (void*)holder);
	
	NSString *title = [[NSString alloc] initWithFormat:@"1 / %d", [self.pictures count]+1];
	self.navigationItem.title = title;
	[title release];
}

- (void)redraw
{
	self.navigationController.navigationBar.hidden = YES;
	self.imageView.image = nil;
	 
	UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	activityView.frame = CENTER_RECT(activityView.frame, self.imageView.frame);
	[self.imageView addSubview:activityView];
	[activityView startAnimating];
	[activityView release];
	
	self.view.frame = CGRectMake(self.view.frame.origin.x, 
									  self.view.frame.origin.y, 
									  self.view.frame.size.height, 
									  self.view.frame.size.width);
	DEBUG_RECT("full view frame:", self.view.frame);
	pthread_t thread;
	image_holder *holder = (image_holder*) malloc(sizeof(image_holder));
	holder->imageView = self.imageView;
	holder->file_name = self.parent.entryForThisView.picture;
	holder->activityView = activityView;
	pthread_create(&thread, nil, (void*)(display_image_in_thread), (void*)holder); 
	
	//CGAffineTransformMakeRotation
}
#pragma mark SWIPE RECOGNIZER
- (void) performLeftSwipe:(UISwipeGestureRecognizer*)Sender
{
	NSInteger saved_loc = _swipe_loc;
	
	if ([pictures count] == 0)
		return;
	
	if ((_swipe_loc+1) < [pictures count]) {
		_swipe_loc++;
		//self.navigationItem.rightBarButtonItem = self.trashButton;
	}
	NSString *picture_name = [self.pictures objectAtIndex:_swipe_loc];
	TRACE("%s, current: %d, new: %d, picture: %s\n", __func__, saved_loc, _swipe_loc, [picture_name UTF8String]);
	
	pthread_t thread;
	
	UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	activityView.frame = CENTER_RECT(activityView.frame, self.imageView.frame);
	[self.imageView addSubview:activityView];
	[activityView startAnimating];
	[activityView release];
	
	image_holder *holder = (image_holder*) malloc(sizeof(image_holder));
	self.imageView.image = nil;
	holder->imageView = self.imageView;
	holder->file_name = picture_name;
	holder->activityView = activityView;
	pthread_create(&thread, nil, (void*)(display_image_in_thread), (void*)holder);
	
	NSString *title = [[NSString alloc] initWithFormat:@"%d / %d",_swipe_loc+2, [self.pictures count]+1];
	self.navigationItem.title = title;
	[title release];
	
	//UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:picture_name]];
	//self.imageView.image = image;
	//[image release];
}

- (void) performRightSwipe:(UISwipeGestureRecognizer*)Sender
{
	NSInteger saved_loc = _swipe_loc;
	NSString *picture_name = nil;
	
	if ((_swipe_loc) >= 0) {
		_swipe_loc--;
	}
	if (_swipe_loc < 0) {
		picture_name = self.parent.entryForThisView.picture;
		//self.navigationItem.rightBarButtonItem = nil;
	}
	else {
		picture_name = [self.pictures objectAtIndex:_swipe_loc];
	}
	TRACE("%s, current: %d, new: %d, picture: %s\n", __func__, saved_loc, _swipe_loc, [picture_name UTF8String]);
	pthread_t thread;
	
	UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	activityView.frame = CENTER_RECT(activityView.frame, self.imageView.frame);
	[self.imageView addSubview:activityView];
	[activityView startAnimating];
	[activityView release];
	
	image_holder *holder = (image_holder*) malloc(sizeof(image_holder));
	holder->imageView = self.imageView;
	holder->file_name = picture_name;
	holder->activityView = activityView;
	pthread_create(&thread, nil, (void*)(display_image_in_thread), (void*)holder);
	
	//UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:picture_name]];
	//self.imageView.image = image;
	//[image release];
	
	NSString *title = [[NSString alloc] initWithFormat:@"%d / %d",_swipe_loc+2, [self.pictures count]+1];
	self.navigationItem.title = title;
	[title release];
	
}

- (void)removeCurrentPicture
{
	NSInteger loc = -1;
	
	if (_swipe_loc >= 0) { // Remove one in the frame
		loc = _swipe_loc;
		NSString *picture = [self.pictures objectAtIndex:_swipe_loc];
		if ([[GeoDatabase sharedGeoDatabaseInstance] removePicture:picture fromJournal:self.parent.entryForThisView deleteFile:YES]) {
			TRACE("%s, success. Index: %d\n", __func__, loc);
			[self.pictures removeObjectAtIndex:loc];
			[self performRightSwipe:nil];
			
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iGeoJournal" message:@"Fail to remove this picture. Try again later!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
	}
	else {
		
		// Remove from the Journal
		if ([self.pictures count] == 0) { // When there is no other pictures in the frame.
			[[GeoDatabase sharedGeoDatabaseInstance] removeJournalPicture:self.parent.entryForThisView];
			[self.navigationController popViewControllerAnimated:YES];
			[self.parent._parent.tableView reloadData];
		}
		else {
			// Replace the journal picture from the first one in the frame.
			NSString *newPicture = [self.pictures objectAtIndex:0];
			[[GeoDatabase sharedGeoDatabaseInstance] replacePicture:newPicture forJournal:self.parent.entryForThisView];
			[[GeoDatabase sharedGeoDatabaseInstance] removePicture:newPicture fromJournal:self.parent.entryForThisView deleteFile:NO];
			
			UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:newPicture]];
			self.imageView.image = image;
			[image release];
			
			[self.pictures removeObjectAtIndex:0];
			[self.parent._parent.tableView reloadData];
		}
	}
}

#pragma mark -
#pragma mark CALLBACK_API
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	TRACE("%s, %d\n", __func__, buttonIndex);
	switch (buttonIndex) {
		case 1:
			[self removeCurrentPicture];
			break;
		default:
			break;
	}
}

- (void)removeThisPicture:(id)sender
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iGeoJournal" message:@"Do you want to remove this picture permanently?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
}
#pragma mark -

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates. 
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [imageScrollView frame].size.height / scale;
    zoomRect.size.width  = [imageScrollView frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    UIView *view = nil;
	TRACE("%s\n", __func__);
    if (scrollView == self.imageScrollView) {
        view = self.imageView;
    }
    return view;
}

/************************************** NOTE **************************************/
/* The following delegate method works around a known bug in zoomToRect:animated: */
/* In the next release after 3.0 this workaround will no longer be necessary      */
/**********************************************************************************/
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	TRACE("%s, scale: %f\n", __func__, scale);
    [scrollView setZoomScale:scale+0.01 animated:NO];
    [scrollView setZoomScale:scale animated:NO];
}

#pragma mark TapDetectingImageViewDelegate methods

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotSingleTapAtPoint:(CGPoint)tapPoint {
    // Single tap shows or hides drawer of thumbnails.
	TRACE("%s, x: %f, y: %f\n", __func__, tapPoint.x, tapPoint.y);
	if (self.navigationController.navigationBar.hidden == YES) {
		[self.navigationController setNavigationBarHidden:NO animated:YES];
	}
	else {
		[self.navigationController setNavigationBarHidden:YES animated:NO];
	}

    //[self toggleThumbView];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint {
    // double tap zooms in
    float newScale = [imageScrollView zoomScale] * ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
	TRACE("%s, x: %f, y: %f\n", __func__, tapPoint.x, tapPoint.y);
    [imageScrollView zoomToRect:zoomRect animated:YES];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint {
    // two-finger tap zooms out
    float newScale = [imageScrollView zoomScale] / ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
	TRACE("%s, x: %f, y: %f\n", __func__, tapPoint.x, tapPoint.y);
    [imageScrollView zoomToRect:zoomRect animated:YES];
}

#pragma mark -
#pragma mark ROTATION
- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = imageScrollView.bounds;
    return CGSizeMake(bounds.size.width * 1, bounds.size.height);
}
/*
- (CGPoint)pointToCenterAfterRotation
{
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.imageScrollView.bounds), CGRectGetMidY(self.imageScrollView.bounds));
    return [self convertPoint:boundsCenter toView:imageView];
}

// returns the zoom scale to attempt to restore after rotation. 
- (CGFloat)scaleToRestoreAfterRotation
{
    CGFloat contentScale = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (contentScale <= self.minimumZoomScale + FLT_EPSILON)
        contentScale = 0;
    
    return contentScale;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}
*/
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	TRACE_HERE;
	// here, our pagingScrollView bounds have not yet been updated for the new interface orientation. So this is a good
    // place to calculate the content offset that we will need in the new orientation
    CGFloat offset = imageScrollView.contentOffset.x;
    CGFloat pageWidth = imageScrollView.bounds.size.width;
    
    if (offset >= 0) {
        firstVisiblePageIndexBeforeRotation = floorf(offset / pageWidth);
        percentScrolledIntoFirstVisiblePage = (offset - (firstVisiblePageIndexBeforeRotation * pageWidth)) / pageWidth;
    } else {
        firstVisiblePageIndexBeforeRotation = 0;
        percentScrolledIntoFirstVisiblePage = offset / pageWidth;
    }    
	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	TRACE("%s, %d\n", __func__, toInterfaceOrientation);
	//DEBUG_RECT("image bounds: ", imageScrollView.bounds);
	
	if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
		toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		DEBUG_RECT("image bounds: ", imageScrollView.bounds);
		self.navigationController.navigationBar.hidden = YES;
		self.view.bounds = CGRectMake(imageScrollView.bounds.origin.x, imageScrollView.bounds.origin.y, 
									  480.0, 320.0);
		imageScrollView.bounds = CGRectMake(imageScrollView.bounds.origin.x, imageScrollView.bounds.origin.y, 
											480.0, 320.0);
		imageScrollView.frame = imageScrollView.bounds;
		imageView.bounds = imageScrollView.bounds;
		self.view.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
		self.imageScrollView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
		self.imageView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
		//imageScrollView.frame = CGRectMake(0.0, 0.0, imageScrollView.frame.size.width, imageScrollView.frame.size.height);
	}
	else {
		self.navigationController.navigationBar.hidden = NO;
		self.view.bounds = CGRectMake(imageScrollView.bounds.origin.x, imageScrollView.bounds.origin.y, 
									  320, 460.0);
		imageScrollView.bounds = CGRectMake(imageScrollView.bounds.origin.x, imageScrollView.bounds.origin.y, 
											320.0, 460.0);
		imageScrollView.frame = imageScrollView.bounds;
		imageView.bounds = imageScrollView.bounds;
		self.view.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
		self.imageScrollView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
		self.imageView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
	}

	DEBUG_RECT("image bounds: ", imageScrollView.bounds);
	DEBUG_RECT("image frame: ", imageScrollView.frame);
	DEBUG_RECT("view frame: ", imageScrollView.frame);
	DEBUG_RECT("tap frame: ", imageView.frame); 
	DEBUG_RECT("tap bound: ", imageView.bounds); 
	DEBUG_RECT("view:", self.view.frame);
	DEBUG_POINT("tap", imageView.center);
	DEBUG_POINT("image", imageScrollView.center);
	DEBUG_POINT("view", self.view.center);
	// recalculate contentSize based on current orientation
    //imageScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    // adjust frames and configuration of each visible page
    //for (ImageScrollView *page in visiblePages) {
       // CGPoint restorePoint = [imageScrollView pointToCenterAfterRotation];
        //CGFloat restoreScale = [imageScrollView scaleToRestoreAfterRotation];
		//imageScrollView.frame = [self frameForPageAtIndex:1];
        //[imageScrollView setMaxMinZoomScalesForCurrentBounds];
        //[imageScrollView restoreCenterPoint:restorePoint scale:restoreScale];
        
    //}
    
    // adjust contentOffset to preserve page location based on values collected prior to location
    //CGFloat pageWidth = imageScrollView.bounds.size.width;
    //CGFloat newOffset = (firstVisiblePageIndexBeforeRotation * pageWidth) + (percentScrolledIntoFirstVisiblePage * pageWidth);
    //imageScrollView.contentOffset = CGPointMake(newOffset, 0);
	
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

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.imageView = nil;
	self.parent = nil;
	self.trashButton = nil;
}


- (void)dealloc {
	[parent release];
    [super dealloc];
}


@end
