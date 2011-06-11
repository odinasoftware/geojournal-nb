//
//  StatusViewController.m
//  JeJuSite
//
//  Created by Jae Han on 7/5/10.
//  Copyright 2010 Home. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "GeoJournalHeaders.h"
#import "StatusViewController.h"
#import "Journal.h"
#import "SlideImageView.h"
#import "GeoDefaults.h"
#import "ImageArrayScrollController.h"

static StatusViewControllerHolder *sharedStatusViewController = nil;

extern NSString *getThumbnailFilename(NSString *filename);
extern NSString *getThumbnailOldFilename(NSString *filename);

@implementation StatusViewControllerHolder

@synthesize statusView=_statusView;
@synthesize delegate;

+ (StatusViewControllerHolder*)sharedStatusViewControllerInstance
{
	if (sharedStatusViewController == nil) {
		[[self alloc] init];
	}
	
	return sharedStatusViewController;
}

+ (id)allocWithZone:(NSZone*)zone
{
	if (sharedStatusViewController == nil) {
		sharedStatusViewController = [super allocWithZone:zone];
		return sharedStatusViewController;
	}
	
	return nil;
}

- (id)init
{
	if (self = [super init]) {
		self.statusView = nil;
		self.delegate = nil;
	}
	
	return self;
}

- (void)removeFromSuperview:(BOOL)notify
{
	NSString *name = nil;
	
	if (self.statusView.view) {
		//[UIView beginAnimations:nil context:UIGraphicsGetCurrentContext()];
		//[UIView setAnimationDuration:0.5];
		
		if (notify == YES) {
			name = [self.statusView.imageArrayView getSelectedImageName];
		}
		
		[self.statusView.view removeFromSuperview];
		self.statusView = nil;
		//[UIView commitAnimations];
	}
	
	if (notify == YES) {
		[self.delegate selectImage:name];
	}

}

/*
UIView *popup;

- (void) initPopUpView {
	self.statusView.view.alpha = 1;
	
	//[self.view addSubview:popup];
	
	[popup addSubview:self.statusView.view];
}
*/
static CGFloat kTransitionDuration = 0.3;

- (CGAffineTransform)transformForOrientation {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (orientation == UIInterfaceOrientationLandscapeLeft) {
		return CGAffineTransformMakeRotation(M_PI*1.5);
	} else if (orientation == UIInterfaceOrientationLandscapeRight) {
		return CGAffineTransformMakeRotation(M_PI/2);
	} else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
		return CGAffineTransformMakeRotation(-M_PI);
	} else {
		return CGAffineTransformIdentity;
	}
}

- (void)bounce2AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/2];
	self.statusView.innerRectangle.transform = [self transformForOrientation];
	[UIView commitAnimations];
}

- (void)bounce1AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/1];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
	self.statusView.innerRectangle.transform = CGAffineTransformScale([self transformForOrientation], 0.9, 0.9);
	[UIView commitAnimations];
}

- (void)showStatusView:(UIView*)parent withJournal:(Journal*)entry withImages:(NSMutableArray*)pictures withMessage:(NSString*)message delegate:(id)dele
{
	if (self.statusView == nil) {
		self.delegate = dele;
		_statusView = [[StatusViewController alloc] init];
		
		[parent addSubview:self.statusView.view];
		CALayer *layer = [self.statusView.innerRectangle layer];
		layer.cornerRadius = 10.0f;	
		
		if (message)
			self.statusView.statusLabel.text = message;
		self.statusView.innerRectangle.transform = CGAffineTransformScale([self transformForOrientation], 0.001, 0.001);
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:kTransitionDuration/1.5];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
		self.statusView.innerRectangle.transform = CGAffineTransformScale([self transformForOrientation], 1.1, 1.1);
		[UIView commitAnimations];
		
		if (pictures && [pictures count] > 0) {
			// Always the fire will the one with the original. 
			//NSString *thumb = getThumbnailFilename(entry.picture);
			//if ([[NSFileManager defaultManager] fileExistsAtPath:[[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:thumb]] == NO) {
			//	[thumb release];
			//	thumb = getThumbnailOldFilename(entry.picture);
			//}
			[pictures insertObject:entry.picture atIndex:0]; //[thumb release];
			//self.imageArrayView.hidden = NO;
			ImageArrayScrollController *controller = self.statusView.imageArrayView;
			controller.imageArray = pictures;
			controller.firstPicturename = entry.picture;
			[controller startLoadingImages];
			//[self.imageScrollViewController performSelectorOnMainThread:@selector(startLoadingImages) withObject:nil waitUntilDone:NO];
			//[self.imageScrollViewController startLoadingImages];
			//[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(startLoadingImageArray:) 
			//																   withObject:self.imageScrollViewController waitUntilDone:NO];
		}
		else {
			//self.imageArrayView.hidden = YES;
			//moveNoArray = self.imageArrayView.frame.size.height;
		}
		
	}
	else {
		NSLog(@"%s, statusview can't be not null.", __func__);
		//self.statusView.view.hidden = NO;
		//[self.statusView.activityView startAnimating];
	}
}

- (ImageArrayScrollController*)getImageArrayController
{
	return self.statusView.imageArrayView;
}

- (void)dealloc
{
	[_statusView release];
	[super dealloc];
}

@end


@implementation StatusViewController

@synthesize innerRectangle;
@synthesize statusLabel;
@synthesize cancelButton;
@synthesize okButton;
@synthesize imageArrayView;

//@synthesize slideImageView;

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
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark BUTTON ACTIONS
-(IBAction)cancelDownloading:(id)sender
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iGeoJournal" message:@"Do you want to cancel this action?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"No", nil];
	[alert show];
	[alert release];
}

- (IBAction)okSelection:(id)sender
{
	[[StatusViewControllerHolder sharedStatusViewControllerInstance] removeFromSuperview:YES];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)cancelSearching
{
	[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(cancelSearching:) withObject:nil waitUntilDone:NO];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0:
			[[StatusViewControllerHolder sharedStatusViewControllerInstance] removeFromSuperview:NO];
			break;
		case 1:
			break;
		case 2:
			
			break;
		default:
			NSLog(@"%s, index error: %d", __func__, buttonIndex);
	}
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
	self.innerRectangle = nil;
	self.statusLabel = nil;
	self.cancelButton = nil;
	self.imageArrayView = nil;
	self.okButton = nil;
}


- (void)dealloc {
	TRACE_HERE;
	[okButton release];
	[imageArrayView release];
	[cancelButton release];
	[innerRectangle release];
	[statusLabel release];
	
    [super dealloc];
}


@end
