//
//  GeoPopOverController.m
//  GeoJournal
//
//  Created by Jae Han on 11/30/11.
//  Copyright (c) 2011 Home. All rights reserved.
//
#import "GCategory.h"
#import "GeoDatabase.h"
#import "GeoJournalHeaders.h"
#import "GeoDefaults.h"
#import "DefaultCategory.h"
#import "GeoPopOverController.h"
#import "NoteViewController.h"

@implementation GeoPopOverController

@synthesize delegate;

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
    
    self.title = @"test";

    TRACE_HERE;
    
    if (self.topViewController == nil) {
        
        //UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editNoteCategory)];
        //self.navigationItem.leftBarButtonItem = editButton;
        
		NoteViewController *aViewController = [[NoteViewController alloc] initWithNibName:@"NoteView" bundle:nil];
		//self.navigationBar.barStyle = UIBarStyleBlackOpaque;
		//self.navigationBarHidden = YES;
        //self.navigationItem.title = @"Edit Category";
        aViewController.delegate = self.delegate;
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
