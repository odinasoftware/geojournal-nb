//
//  StatusViewController.m
//  JeJuSite
//
//  Created by Jae Han on 7/5/10.
//  Copyright 2010 Home. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "GeoJournalHeaders.h"
#import "ProgressViewController.h"

static ProgressViewControllerHolder *sharedProgressViewController = nil;

@implementation ProgressViewControllerHolder

@synthesize statusView=_statusView;

+ (ProgressViewControllerHolder*)sharedStatusViewControllerInstance
{
	if (sharedProgressViewController == nil) {
		[[self alloc] init];
	}
	
	return sharedProgressViewController;
}

+ (id)allocWithZone:(NSZone*)zone
{
	if (sharedProgressViewController == nil) {
		sharedProgressViewController = [super allocWithZone:zone];
		return sharedProgressViewController;
	}
	
	return nil;
}

- (id)init
{
	if ((self = [super init])) {
		self.statusView = nil;
		_statusType = DEFAULT_PROGRESS_TYPE;
	}
	
	return self;
}

- (void)removeFromSuperview:(status_view_type_t)type 
{
	//if (self.statusView.view.hidden == NO && (_statusType == type || type == ALL_STATUS_TYPE)) {
		//[self.statusView.view removeFromSuperview];
		[self.statusView.activityView stopAnimating];
		self.statusView.view.hidden = YES;
		_statusType = DEFAULT_PROGRESS_TYPE;
	//}
}

- (void)showStatusView:(UIView*)parent type:(status_view_type_t)type
{
	_statusType = type;
    TRACE("%s, view type: %d\n", __func__, _statusType);
	if (self.statusView == nil) {
		_statusView = [[ProgressViewController alloc] initWithType:type];
		[parent addSubview:self.statusView.view];
		CALayer *layer = [self.statusView.innerRectangle layer];
		layer.cornerRadius = 10.0f;	
		[self.statusView.activityView startAnimating];
	}
	else {
		self.statusView.view.hidden = NO;
        //self.statusView.view_type = type;
		[self.statusView.activityView startAnimating];
	}
}

- (void)dealloc
{
	[_statusView release];
	[super dealloc];
}

@end


@implementation ProgressViewController

@synthesize innerRectangle;
@synthesize statusLabel;
@synthesize cancelButton;
@synthesize activityView;
@synthesize view_type;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (id)initWithType:(status_view_type_t)type
{
    if ((self = [super init])) {
        view_type = type;
        TRACE("%s, %p view type: %d\n", __func__, self, view_type);
        
        switch (view_type) {
            case DEFAULT_PROGRESS_TYPE:
                self.statusLabel.text = @"Sync with iCloud ...";
                break;
            case CLOUD_READY_PROGRESS_TYPE:
                self.statusLabel.text = @"Old version detected. Will need to convert to iCloud ready. It will take some time. Please wait ...";
                break;
            default:
                break;
        }
    }
    
    return self;
}
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
	TRACE("%s\n", __func__);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iCloud Sync" 
                                                    message:@"Do you really want to cancel syncing with iCloud?" 
                                                    delegate:self 
                                          cancelButtonTitle:@"Cancel" 
                                          otherButtonTitles:@"NO", nil];
	[alert show];
	[alert release];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)cancelSearching
{
    // TODO: cancel cloud sync
    TRACE("%s, %p\n", __func__, self.view.superview);
    UIView *controller = self.view.superview;
    [[ProgressViewControllerHolder sharedStatusViewControllerInstance] removeFromSuperview:DEFAULT_PROGRESS_TYPE];
    /*
    if ([controller isKindOfClass:[ProductViewController class]]) {
    //if (view_type == THUMB_STATUS_TYPE) {
        [(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(cancelSearching:) 
                                                                           withObject:nil waitUntilDone:NO];
    }
    else {
        [(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(cancelPageSearching:) 
                                                                           withObject:nil waitUntilDone:NO];
    }
     */
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0:
            [self cancelSearching];
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
}


- (void)dealloc {
	[cancelButton release];
	[innerRectangle release];
	[statusLabel release];
	
    [super dealloc];
}


@end
