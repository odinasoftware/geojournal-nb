//
//  PadEditViewController.m
//  GeoJournal
//
//  Created by Jae Han on 9/11/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "PadEditViewController.h"
#import "GeoJournalHeaders.h"

#define INSIDE_VIEW_X		0.0
#define INSIDE_VIEW_Y		0.0
#define INSIDE_VIEW_WIDTH	320.0
#define INSIDE_VIEW_HEIGHT	460.0

@implementation PadEditViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    TRACE_HERE;
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

#pragma mark FINISH ACTIONS
- (void)cancelAction:(id)sender
{
	self.text = nil;
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)doneAction:(id)sender
{
	[self.navigationController dismissModalViewControllerAnimated:YES];
}
#pragma mark -
#pragma mark KEYBOARD Operations
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown:)
												 name:UIKeyboardDidShowNotification object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasHidden:)
												 name:UIKeyboardDidHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
	TRACE_HERE;
    if (keyboardShown)
		return;
	
    NSDictionary* info = [aNotification userInfo];
	
    // Get the size of the keyboard.
    NSValue* aValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
	NSTimeInterval animationDuration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    // Resize the scroll view (which is the root view of the window)
    CGRect viewFrame = CGRectMake(INSIDE_VIEW_X, INSIDE_VIEW_Y, INSIDE_VIEW_WIDTH, INSIDE_VIEW_HEIGHT);
    viewFrame.size.height -= keyboardSize.height;
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
	
    TRACE("%s, %f\n", __func__, viewFrame.size.height);
    self.view.frame = viewFrame; 
	[UIView commitAnimations];
    // Scroll the active text field into view.
    //CGRect textFieldRect = [textView frame];
    //[self.insideView scrollRectToVisible:textFieldRect animated:YES];
	
    keyboardShown = YES;
}


// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardWasHidden:(NSNotification*)aNotification
{
	TRACE_HERE;
    //NSDictionary* info = [aNotification userInfo];
	
    // Get the size of the keyboard.
    //NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    //CGSize keyboardSize = [aValue CGRectValue].size;
	
    // Reset the height of the scroll view to its original value
    CGRect viewFrame = CGRectMake(INSIDE_VIEW_X, INSIDE_VIEW_Y, INSIDE_VIEW_WIDTH, INSIDE_VIEW_HEIGHT);
    //viewFrame.size.height += keyboardSize.height;
    self.view.frame = viewFrame;
	
	TRACE("%s, %f\n", __func__, viewFrame.size.height);
    keyboardShown = NO;
}


#pragma mark -

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.textView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
