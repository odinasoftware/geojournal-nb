//
//  GeoPadMainViewController.m
//  GeoJournal
//
//  Created by Jae Han on 11/19/11.
//  Copyright (c) 2011 Home. All rights reserved.
//
#import "GeoJournalHeaders.h"
#import "GeoPadMainViewController.h"
#import "GeoPadTableViewController.h"
#import "GeoPopOverController.h"
#import "NoteViewController.h"
#import "ShowDisplayOptionController.h"
#import "PadMapViewController.h"

@implementation GeoPadMainViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    TRACE("%s, top: %s\n", __func__, [NSStringFromClass([self.topViewController class]) UTF8String]);
    //Class = [self.topViewController class];
    
    if (self.topViewController == nil) {
		GeoPadTableViewController *aViewController = [[GeoPadTableViewController alloc] initWithNibName:@"GeoPadTableViewController" bundle:nil];
        
		[self pushViewController:aViewController animated:YES];
		[aViewController release];
	}
    
}

- (void)showCategoryOptions:(id)sender
{
    TRACE_HERE;
	
    
    GeoPopOverController *controller = [[GeoPopOverController alloc] initWithNibName:@"GeoPopOverController" bundle:nil];
    //NoteViewController *controller = [[NoteViewController alloc] initWithNibName:@"NoteView" bundle:nil];
    //controller.delegate = self;
    UIPopoverController *aPopover = [[UIPopoverController alloc] initWithContentViewController:controller];
    [controller release];
    
    
    [aPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)displayShowOptions:(id)sender
{
    ShowDisplayOptionController *controller = [[ShowDisplayOptionController alloc] initWithNibName:@"ShowDisplayOptionController" bundle:nil];
    //NoteViewController *controller = [[NoteViewController alloc] initWithNibName:@"NoteView" bundle:nil];
    controller.bypassDelegate = self;
    UIPopoverController *aPopover = [[UIPopoverController alloc] initWithContentViewController:controller];
    [controller release];
    
    
    [aPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

}

- (void)changeDisplayView:(NSInteger)viewIndex
{
    TRACE("%s, index: %d, %s\n", __func__, viewIndex, [NSStringFromClass([self.topViewController class]) UTF8String]);
    
    for (UIViewController *v in self.viewControllers) {
        TRACE("v: %s\n", [NSStringFromClass([v class]) UTF8String]);
    }
    switch (viewIndex) {
        case 0:
            if (![self.topViewController isKindOfClass:[GeoPadTableViewController class]]) {
                // Show NoteViewController
                [self popViewControllerAnimated:NO];
                NoteViewController *aViewController = [[NoteViewController alloc] initWithNibName:@"NoteView" bundle:nil];
                
                [self pushViewController:aViewController animated:YES];
                [aViewController release];
            }
            break;
        case 1:
            if (![self.topViewController isKindOfClass:[PadMapViewController class]]) {
                
                //[self popViewControllerAnimated:NO];
                PadMapViewController *aViewController = [[PadMapViewController alloc] initWithNibName:@"PadMapViewController" bundle:nil];
                [self setViewControllers:[NSArray arrayWithObjects:aViewController, nil] animated:YES];
                //[self pushViewController:aViewController animated:YES];
                //[aViewController release];
            }
            break;
        case 2:
            break;
        default:
            break;
    }
}
@end
