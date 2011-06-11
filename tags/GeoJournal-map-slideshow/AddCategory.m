//
//  AddCategory.m
//  GeoJournal
//
//  Created by Jae Han on 7/8/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "AddCategory.h"
#import "GeoJournalHeaders.h"

#define kLeftMargin				20.0
#define kTopMargin				20.0
#define kRightMargin			20.0
#define kTweenMargin			10.0

#define kTextFieldHeight		30.0
#define kTextFieldWidth			280.0

#define kViewTag				1

@implementation AddCategory

@synthesize textInputField;
@synthesize theTableView;
@synthesize saveResult;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	saveResult = NO;
	self.hidesBottomBarWhenPushed = YES;
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
									 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
	
	//self.navigationItem.prompt = @"Select article sections";
	self.navigationItem.leftBarButtonItem = cancelButton;
	[cancelButton release];
	
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
								   initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
	self.navigationItem.rightBarButtonItem = doneButton;
	[doneButton release];
	
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// TODO: Get the default category and categories from database
	// Define NSArray for default category and fetch from database rest.
	
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Type a new category:";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return @"Type a new category here.";
}


#pragma mark UITableView delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO: need to define table cells.
	
	NSString* identity = @"CategoryTypeCell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identity];
	
	if (cell == nil) {
		//cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity] autorelease];
		UITextField *textField = self.textInputField;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell addSubview:textField];
	}
	
	
	
	//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	TRACE("%s, %s\n", __func__, [textField.text UTF8String]);
	// the user pressed the "Done" button, so dismiss the keyboard
	[textField resignFirstResponder];
	return YES;
}

- (UITextField *)textInputField
{
	if (textInputField == nil)
	{
		CGRect frame = CGRectMake(kLeftMargin, 8.0, kTextFieldWidth, kTextFieldHeight);
		textInputField = [[UITextField alloc] initWithFrame:frame];
		
		textInputField.borderStyle = UITextBorderStyleNone;
		textInputField.textColor = [UIColor blackColor];
		textInputField.font = [UIFont systemFontOfSize:17.0];
		//textInputField.placeholder = @"<enter text>";
		textInputField.backgroundColor = [UIColor whiteColor];
		textInputField.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
		
		textInputField.keyboardType = UIKeyboardTypeDefault;	// use the default type input method (entire keyboard)
		textInputField.returnKeyType = UIReturnKeyDone;
		
		textInputField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
		
		textInputField.tag = kViewTag;		// tag this control so we can remove it later for recycled cells
		
		textInputField.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed
	}	
	return textInputField;
}

- (void)doneAction
{
	// Save the new value
	self.saveResult = YES;
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelAction
{
	// Cancel the changes
	self.saveResult = NO;
	[self.navigationController popViewControllerAnimated:YES];
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
	//self. = nil;
	self.theTableView = nil;
	[textInputField release];
	textInputField = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
