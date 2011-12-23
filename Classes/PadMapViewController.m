//
//  PadMapViewController.m
//  GeoJournal
//
//  Created by Jae Han on 12/7/11.
//  Copyright (c) 2011 Home. All rights reserved.
//
#import "GeoJournalHeaders.h"
#import "GeoPadHeaders.h"
#import "GeoPadTableViewController.h"
#import "GCategory.h"
#import "GeoDatabase.h"
#import "Journal.h"
#import "GeoDefaults.h"
#import "DateIndex.h"
#import "DefaultCategory.h"

#import "PadMapViewController.h"

#define NUMBER_OF_MARK_CHUNK		10

@implementation PadMapViewController

@synthesize categoryBar, searchBar, settingBar, composeBar, viewsBar, titleLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _numberOfPins = NUMBER_OF_MARK_CHUNK;
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
    
    // Create Buttons for the view controller
    self.categoryBar.target = self.navigationController;
    self.categoryBar.action = @selector(showCategoryOptions:);
    self.viewsBar.target = self.navigationController;
    self.viewsBar.action = @selector(displayShowOptions:);
    
    NSString *active = [GeoDefaults sharedGeoDefaultsInstance].activeCategory;
    TRACE("%s, active: %s\n", __func__, [active UTF8String]);
    //self.titleLabel.frame = CENTER_RECT(self.titleLabel.frame, self.toolbar.frame);
    //self.titleLabel.text = active;
    self.titleLabel.text = active;
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
