//
//  MapController.m
//  GeoJournal
//
//  Created by Jae Han on 5/23/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "MapController.h"
#import "MapViewController.h"
#import "GeoJournalHeaders.h"

@implementation MapController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.delegate = self;
	
	if (self.topViewController == nil) {
		MapViewController *aMapViewController = [[MapViewController alloc] initWithNibName:@"MapView" bundle:nil];
		[self pushViewController:aMapViewController animated:YES];
		[aMapViewController release];
	}
}

#ifdef ALLOW_ROTATING
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    TRACE_HERE;
    [self popViewControllerAnimated:NO];
    
    DEBUG_RECT("map controller:", self.view.bounds);
    MapViewController *aMapViewController = [[MapViewController alloc] initWithNibName:@"MapView" bundle:nil];
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || 
        self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        aMapViewController.hidesBottomBarWhenPushed = YES;
        [aMapViewController adjustOrientation:(CGRect)self.view.bounds];
    }

    [self pushViewController:aMapViewController animated:NO];
    
    [aMapViewController release];

}
#endif
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
	//[self.topViewController release];
	TRACE("%s\n", __func__);
}


- (void)dealloc {
	TRACE_HERE;
    [super dealloc];
}


@end
