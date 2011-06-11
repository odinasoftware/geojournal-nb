//
//  SearchNavigationController.m
//  GeoJournal
//
//  Created by Jae Han on 8/8/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "SearchNavigationController.h"
#import "SearchController.h"
#import "GeoJournalHeaders.h"

@implementation SearchNavigationController

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
		SearchController *aViewController = [[SearchController alloc] initWithNibName:@"SearchController" bundle:nil];
		//self.navigationBar.barStyle = UIBarStyleBlackOpaque;
		//self.navigationBarHidden = YES;
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

/* 
 * This method removes the top view controller from the stack and makes the new top of the stack the active view controller. 
 * If the view controller at the top of the stack is the root view controller, this method does nothing. 
 * In other words, you cannot pop the last item on the stack.
 */
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
