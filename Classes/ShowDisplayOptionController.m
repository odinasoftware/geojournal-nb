//
//  ShowDisplayOptionController.m
//  GeoJournal
//
//  Created by Jae Han on 12/6/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "ShowDisplayOptionController.h"
#import "ShowDisplayOptionsView.h"
#import "GeoPadMainViewController.h"

@implementation ShowDisplayOptionController

@synthesize bypassDelegate;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.topViewController == nil) {
		ShowDisplayOptionsView *aViewController = [[ShowDisplayOptionsView alloc] initWithNibName:@"ShowDisplayOptionsView" bundle:nil];
		//self.navigationBar.barStyle = UIBarStyleBlackOpaque;
		//self.navigationBarHidden = YES;
        aViewController.delegate = self.bypassDelegate;

		[self pushViewController:aViewController animated:YES];
		[aViewController release];
	}

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

@end
