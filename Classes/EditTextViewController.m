//
//  EditTextViewController.m
//  GeoJournal
//
//  Created by Jae Han on 9/5/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "EditTextViewController.h"
#import "GeoJournalHeaders.h"

@interface EditTextViewController ()

@end

@implementation EditTextViewController
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
 */

- (void)viewDidLoad
{
    [super viewDidLoad];
    TRACE_HERE;
	// Do any additional setup after loading the view.
    keyboardShown = NO;
	[self registerForKeyboardNotifications];
	
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
									 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
	
	self.navigationItem.leftBarButtonItem = cancelButton;
	[cancelButton release];
	
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
								   initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = doneButton;
	[doneButton release];
	
	self.navigationItem.title = @"Edit Note";
	
	self.textView.text = self.text;

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
