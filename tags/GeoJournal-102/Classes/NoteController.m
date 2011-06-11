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
		NoteViewController *aNoteViewController = [[NoteViewController alloc] initWithNibName:@"NoteView" bundle:nil];
		TRACE("%s, controller: %p\n", __func__, aNoteViewController);
		[self pushViewController:aNoteViewController animated:YES];
		[aNoteViewController release];
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
	TRACE("%s\n", __func__);
	//[self.topViewController release];
}


- (void)dealloc {
	TRACE_HERE;
    [super dealloc];
}


@end
