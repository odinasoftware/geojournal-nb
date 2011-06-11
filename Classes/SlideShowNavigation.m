//
//  SlideShowNavigation.m
//  GeoJournal
//
//  Created by Jae Han on 7/20/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "SlideShowNavigation.h"
#import "SlideShowViewController.h"
#import "GeoJournalHeaders.h"

@implementation SlideShowNavigation

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
	
	if (self.topViewController == nil) {
		SlideShowViewController *aViewController = [[SlideShowViewController alloc] initWithNibName:@"SlideShowView" bundle:nil];
		self.navigationBar.barStyle = UIBarStyleBlackOpaque;
		[self pushViewController:aViewController animated:YES];
		[aViewController release];
	}
	
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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	TRACE_HERE;
	//[self.topViewController release];
}


- (void)dealloc {
	TRACE_HERE;
    [super dealloc];
}


@end
