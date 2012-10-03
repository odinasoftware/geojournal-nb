//
//  PadEntryViewController.m
//  GeoJournal
//
//  Created by Jae Han on 11/14/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "GeoPadHeaders.h"
#import "PadEntryViewController.h"
#import "GeoDefaults.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "GeoDatabase.h"
#import "GeoSession.h"
#import "JournalViewController.h"
#import "PadEditViewController.h"
#import "ImageArrayScrollController.h"
#import "FullImageViewController.h"
#import "StatusViewController.h"
#import "HorizontalViewController.h"

#define BOTTOM_MARGIN			80
#define ORIG_WIDTH              768
#define ORIG_HEIGHT             1024

extern NSString *getTitle(NSString *content);
extern NSString *getThumbnailFilename(NSString *filename);
extern NSString *getThumbnailOldFilename(NSString *filename);
extern void saveImageToFile(UIImage *image, NSString *filename);
extern UIImage *getReducedImage(UIImage *image, float ratio);
extern void *display_image_in_thread(void *arg);
extern NSString *getPrinterableDate(NSDate *date, NSInteger *day);

@implementation PadEntryViewController
//@synthesize editTextController;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
            [self syncWithFacebook];
            break;
        case 2:
            if ([TWTweetComposeViewController class]) {
                [self syncWithTweet];
            }
            else {
                [self syncWithMail];
            }
            break;
        case 3:
            [self syncWithMail];
            break;
        case 0:
            break;
        default:
            break;
    }
}


#pragma mark -
- (void)chooseActions:(id)sender
{
    UIAlertView *alert = nil;
    
    if ([TWTweetComposeViewController class]) {
        alert = [[UIAlertView alloc] initWithTitle:@"Sync Article" 
                                           message:@""
                                          delegate:self 
                                 cancelButtonTitle:@"Cancel" 
                                 otherButtonTitles:@"Facebook", @"Tweet", @"Send mail", nil];
    }
    else {
        alert = [[UIAlertView alloc] initWithTitle:@"Sync Article" 
                                           message:@""
                                          delegate:self 
                                 cancelButtonTitle:@"Cancel" 
                                 otherButtonTitles:@"Facebook", @"Send mail", nil];
    }
	[alert show];
	[alert release];
    
}

- (void)viewDidLoad
{
    TRACE_HERE;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _sync_action = NO_DEFAULT_ACTION;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                                           target:self 
                                                                                           action:@selector(reloadArticles:)];
	//defaultTintColor = [segmentedControl.tintColor retain];	// keep track of this for later
	
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                          target:self 
                                                                          action:@selector(chooseActions:)];
	self.navigationItem.rightBarButtonItem = item;
    [item release];
	
    _frameRect = self.imageFrameView.frame;
	_imageRect = self.imageForJournal.frame;
	_containerViewRect = self.containerView.frame;
	_creationDateLabelRect = self.creationDateLabel.frame;
	_locationLabelRect = self.locationLabel.frame;
	_textForJournalRect = self.textForJournal.frame;
	_stretchButtonRect = self.stretchButton.frame;
    
	fontSize = [[GeoDefaults sharedGeoDefaultsInstance].defaultFontSize intValue];
	if (fontSize < DEFAULT_FONT_SIZE) {
		fontSize = DEFAULT_FONT_SIZE;
	}
    //self.navigationController.navigationBarHidden = NO;
    //self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    //self.toolbar.userInteractionEnabled = YES;
    //UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:nil];
    //[self.toolbar setItems:self.toolbar.items];
    char *orientation;
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            orientation = "UIInterfaceOrientationPortrait";
            break;
        case UIInterfaceOrientationLandscapeLeft:
            orientation = "UIInterfaceOrientationLandscapeLeft";
            break;
        case UIInterfaceOrientationLandscapeRight:
            orientation = "UIInterfaceOrientationLandscapeRight";
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            orientation = "UIInterfaceOrientationPortraitUpsideDown";
            break;
        default:
            break;
    }
    
    TRACE(">>>>>>>>>>>> %s >>>>>>>>>>: %s\n", __func__, orientation);
    DEBUG_RECT("view: ", self.view.frame);
    DEBUG_RECT("view: ", self.view.superview.frame);
    DEBUG_RECT("Scroll View:", self.scrollView.frame);
    
    //if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft  || 
    //    self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
    //    TRACE("Will change frame to landscape.\n");
        
    //}
    
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, ORIG_WIDTH, ORIG_HEIGHT);
}



- (void)viewWillDisappear:(BOOL)animated
{
    // XXX: When this is disappeared, it need to tell this is hidden,
    // so it won't show up.
    self.navigationController.navigationBarHidden = YES;
}

#pragma ROTATION_EVENT
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    TRACE_HERE;
    double rotation = 0.0;
    double sign = 1.0;
    char *orientation;
    CGRect frame;
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            orientation = "UIInterfaceOrientationPortrait";
            frame = CGRectMake(0.0, 00.0, 768.0, 1004.0);
            //if (fromInterfaceOrientation ==UIInterfaceOrientationLandscapeLeft)
            sign = 1.0;
            rotation = degreesToRadian(360);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            orientation = "UIInterfaceOrientationLandscapeLeft";
            frame = CGRectMake(0.0, 0.0, 748.0, 1024.0);
            //if (fromInterfaceOrientation == UIInterfaceOrientationPortrait)
            sign = -1.0;
            rotation = degreesToRadian(90);
            break;
        case UIInterfaceOrientationLandscapeRight:
            orientation = "UIInterfaceOrientationLandscapeRight";
            frame = CGRectMake(0.0, 00.0, 748.0, 1024.0);
            //if (fromInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
            sign = 1.0;
            rotation = degreesToRadian(90);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            orientation = "UIInterfaceOrientationPortraitUpsideDown";
            frame = CGRectMake(0.0, 00.0, 768.0, 1004.0);
            //if (fromInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
            sign = 1.0;
            rotation = degreesToRadian(180);
            break;
        default:
            break;
    }
    
    
    if (rotation > 0.0) {
        rotation = sign * rotation;
        CGAffineTransform xform = CGAffineTransformMakeRotation(rotation);
        //self.navigationController.navigationBar.transform = xform;
        //self.view.transform = xform;
        //self.navigationController.view.transform = xform;
        //[UIView commitAnimations];
    }
    //self.view.frame = frame;
    //self.navigationController.navigationBar.frame = CGRectMake(20, 0, 44, 1024.0 /*self.navigationController.navigationBar.frame.size.height*/);
    TRACE("%s: %s, %f\n", __func__, orientation, rotation);    
    //self.view.superview.transform = xform;
    _toOrientation = toInterfaceOrientation;

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    TRACE_HERE;
    //if(UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
    //    TRACE("OK, detect");
    //}
    // TODO: the roation is based on the original view always. 
    //_toOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    double rotation = 0.0;
    double sign = 1.0;
    char *orientation;
    CGRect frame;
    switch (_toOrientation) {
        case UIInterfaceOrientationPortrait:
            orientation = "UIInterfaceOrientationPortrait";
            frame = CGRectMake(0.0, 00.0, 768.0, 1004.0);
            //if (fromInterfaceOrientation ==UIInterfaceOrientationLandscapeLeft)
                //sign = 1.0;
            //rotation = degreesToRadian(180);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            orientation = "UIInterfaceOrientationLandscapeLeft";
            frame = CGRectMake(00.0, 0.0, 748.0, 1024.0);
            //if (fromInterfaceOrientation == UIInterfaceOrientationPortrait)
            sign = -1.0;
            rotation = degreesToRadian(90);
            break;
        case UIInterfaceOrientationLandscapeRight:
            orientation = "UIInterfaceOrientationLandscapeRight";
            frame = CGRectMake(0.0, 00.0, 748.0, 1024.0);
            //if (fromInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
            sign = 1.0;
            rotation = degreesToRadian(90);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            orientation = "UIInterfaceOrientationPortraitUpsideDown";
            frame = CGRectMake(0.0, 00.0, 768.0, 1004.0);
            //if (fromInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
            sign = -1.0;
            rotation = degreesToRadian(90);
            break;
        default:
            break;
    }

    /*
    if (rotation > 0.0) {
        rotation = sign * rotation;
        CGAffineTransform xform = CGAffineTransformMakeRotation(rotation);
        self.navigationController.navigationBar.transform = xform;
        self.view.transform = xform;
        [UIView commitAnimations];
    }
    */
    
    
    TRACE("%s: %s, %f\n", __func__, orientation, rotation);
    
    UIView *p = self.view.superview;
    //self.view.superview.frame = frame;
    TRACE("===============\n");
    TRACE("%s, superview: %p\n", __func__, p);
    DEBUG_RECT("entry view: ", self.view.frame);
    DEBUG_RECT("entry parent view: ", p.frame);
    DEBUG_RECT("entry bounds: ", self.view.bounds);
    DEBUG_POINT("ebtrt center: ", self.view.center);
    //DEBUG_RECT("table: ", self.tableView.frame);
    UIWindow *w = [UIApplication sharedApplication].delegate.window;
    DEBUG_RECT("entry window: ", w.frame);
    DEBUG_RECT("navigationBar: ", self.navigationController.navigationBar.frame);
    TRACE("===============\n");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    TRACE_HERE;
    return YES;
}
#pragma -

- (IBAction)popUpPrevView:(id)sender
{
    [self.view removeFromSuperview];
}

- (IBAction)editText:(id)sender
{
    
	PadEditViewController *section = [[PadEditViewController alloc] initWithNibName:@"PadEditViewController" bundle:nil];
	section.text = self.entryForThisView.text;
	//UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:section];
	self.editTextController = section;
	[section release];
    
	//nc.navigationBar.tintColor = [UIColor colorWithRed:0.0286 green:0.6062 blue:0.3575 alpha:1.0]; // green
	//nc.navigationBar.tintColor = [UIColor colorWithRed:0.6745 green:0.1020 blue:0.1529 alpha:1.0]; // read
	//nc.navigationBar.tintColor = [UIColor colorWithRed:1.0 green:0.97 blue:0.60 alpha:1.0]; // yellow
	
	[self.view addSubview:section.view];
	//[nc release];		
	
}

- (void)viewDidUnload {
    [super viewDidUnload];
    TRACE_HERE;
}

@end
