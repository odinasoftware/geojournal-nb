//
//  NoteController.m
//  GeoJournal
//
//  Created by Jae Han on 5/23/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "NoteController.h"
#import "NoteViewController.h"
#import "GeoJournalHeaders.h"
#import "JournalViewController.h"
#import "HorizontalViewController.h"
#import "JournalEntryViewController.h"

@implementation NoteController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
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
	self.delegate = self;
 
	if (self.topViewController == nil) {
		JournalViewController *aNoteViewController = [[JournalViewController alloc] initWithNibName:@"JournalViewController" bundle:nil];
		TRACE("%s, controller: %p\n", __func__, aNoteViewController);
		[self pushViewController:aNoteViewController animated:YES];
		[aNoteViewController release];
	}
}

/*
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    TRACE_HERE;
    [self popViewControllerAnimated:NO];
    
    DEBUG_RECT("journal controller:", self.view.bounds);
    JournalViewController *aViewController = [[JournalViewController alloc] initWithNibName:@"JournalViewController" bundle:nil];
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || 
        self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        aViewController.hidesBottomBarWhenPushed = YES;
        [aViewController adjustOrientation:(CGRect)self.view.bounds];
    }
    
    [self pushViewController:aViewController animated:NO];
    
    [aViewController release];
    
}
 */

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma Rotation

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    BOOL rotate = NO;
    
    if ([self.topViewController isKindOfClass:[JournalEntryViewController class]] ||
        [self.topViewController isKindOfClass:[HorizontalViewController class]])
        rotate = YES;
    
    TRACE("%s, rotate: %d\n", __func__, rotate);
    return rotate;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    TRACE_HERE;
    if ([self.topViewController isKindOfClass:[JournalEntryViewController class]]) {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            
            //[self popViewControllerAnimated:NO];
            HorizontalViewController *controller = [[HorizontalViewController alloc] initWithNibName:@"HorizontalViewController" bundle:nil];
            
            
            self.navigationBarHidden = YES;
            controller.hidesBottomBarWhenPushed = YES;
            controller.view.frame = CGRectMake(0.0, 0.0, 480.0, 320.0);
            [self pushViewController:controller animated:NO];
            [controller release];
            
        }
    }
    else if ([self.topViewController isKindOfClass:[HorizontalViewController class]]) {
        if (toInterfaceOrientation == UIInterfaceOrientationPortrait ||
            toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            
            self.navigationBarHidden = NO;
            [self popViewControllerAnimated:NO];
            
            
        }
    }

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	TRACE_HERE;
    
    DEBUG_RECT("hori:", self.view.frame);
    
    
}

#pragma -

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	TRACE("%s\n", __func__);
	//[self.topViewController release];
}


- (void)dealloc {
	TRACE_HERE;
    [super dealloc];
}


@end
