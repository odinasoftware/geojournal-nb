//
//  TextInputController.m
//  GeoJournal
//
//  Created by Jae Han on 7/9/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "TextInputController.h"
#import "GeoJournalHeaders.h"

#define kLeftMargin				20.0
#define kTopMargin				20.0
#define kRightMargin			20.0
#define kTweenMargin			10.0

#define kTextFieldHeight		20.0
#define kTextViewHeight			20.0
#define kTextFieldWidth			280.0

#define kViewTag				1

@implementation TextInputController

@synthesize theTableView;
@synthesize titleView, contentView;

- (id)init
{
	if ((self = [super init])) {
		[self registerForKeyboardNotifications];
		keyboardShown = NO;
	}
	return self;
}

// Call this method somewhere in your view controller setup code.
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
	//NSTimeInterval animationDuration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    // Get the size of the keyboard.
    NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
	
    // Resize the scroll view (which is the root view of the window)
    CGRect viewFrame = [theTableView frame];
	TRACE("%s, before: x: %f, y: %f, width: %f, height: %f\n", __func__, viewFrame.origin.x, viewFrame.origin.y, viewFrame.size.width, viewFrame.size.height);
    viewFrame.size.height -= keyboardSize.height;
	TRACE("%s, after: x: %f, y: %f, width: %f, height: %f\n", __func__, viewFrame.origin.x, viewFrame.origin.y, viewFrame.size.width, viewFrame.size.height);
	//[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    //[UIView setAnimationDuration:animationDuration];

    theTableView.frame = viewFrame;
	//[UIView commitAnimations];
    // Scroll the active text field into view.
    CGRect textFieldRect = [activeView frame];
	TRACE("%s, rect:x: %f, y: %f, width: %f, height: %f\n", __func__, textFieldRect.origin.x, textFieldRect.origin.y, textFieldRect.size.width, textFieldRect.size.height);
	//textFieldRect.size.height = viewFrame.size.height;
    //[theTableView scrollRectToVisible:textFieldRect animated:YES];
	
    keyboardShown = YES;
}


// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardWasHidden:(NSNotification*)aNotification
{
	TRACE_HERE;
    NSDictionary* info = [aNotification userInfo];
	
    // Get the size of the keyboard.
    NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
	
    // Reset the height of the scroll view to its original value
    CGRect viewFrame = [theTableView frame];
    viewFrame.size.height += keyboardSize.height;
    theTableView.frame = viewFrame;
	
    keyboardShown = NO;
}


- (void)textViewDidBeginEditing:(UITextView *)textField
{
	TRACE("%s\n", __func__);
    activeView = textField;
}

- (void)textViewDidEndEditing:(UITextView *)textField
{
	TRACE("%s\n", __func__);
    activeView = nil;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// TODO: Get the default category and categories from database
	// Define NSArray for default category and fetch from database rest.
	
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *str = nil;
	
	if (section	== 0) {
		str = @"Title";
	}
	else if (section == 1) {
		str = @"Content";
	}
	else {
		NSLog(@"%s: unknown section: %d", __func__, section);
	}
	return str;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return @"Type a new category here.";
}
 */

- (UITextField*)titleView
{
	if (titleView == nil)
	{
		CGRect frame = CGRectMake(kLeftMargin, 8.0, kTextFieldWidth, kTextFieldHeight);
		titleView = [[UITextField alloc] initWithFrame:frame];
		
		titleView.borderStyle = UITextBorderStyleNone;
		titleView.textColor = [UIColor blackColor];
		titleView.font = [UIFont systemFontOfSize:14.0];
		//titleView.placeholder = @"<enter text>";
		titleView.backgroundColor = [UIColor whiteColor];
		titleView.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
		
		titleView.keyboardType = UIKeyboardTypeDefault;	// use the default type input method (entire keyboard)
		titleView.returnKeyType = UIReturnKeyDone;
		
		titleView.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
		
		titleView.tag = kViewTag;		// tag this control so we can remove it later for recycled cells
		
		titleView.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed
	}	
	
	return titleView;
}

- (UITextView*)contentView
{
	if (contentView == nil) {
		CGRect frame = CGRectMake(kLeftMargin, 8.0, kTextFieldWidth, kTextViewHeight);
		contentView = [[[UITextView alloc] initWithFrame:frame] autorelease];
		contentView.textColor = [UIColor blackColor];
		contentView.font = [UIFont fontWithName:@"Arial" size:14];
		contentView.delegate = self;
		contentView.backgroundColor = [UIColor whiteColor];
		
		contentView.text = @"Now is the time for all good developers to come to serve their country.\n\nNow is the time for all good developers to come to serve their country.\n\n\n\n\n\n\n\n\n\n\n\n\n\nEnd.";
		contentView.returnKeyType = UIReturnKeyDefault;
		contentView.keyboardType = UIKeyboardTypeDefault;	// use the default type input method (entire keyboard)
		contentView.scrollEnabled = YES;
		contentView.editable = YES;
		
		// this will cause automatic vertical resize when the table is resized
		//contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		
		// note: for UITextView, if you don't like autocompletion while typing use:
		// myTextView.autocorrectionType = UITextAutocorrectionTypeNo;
		
		//[self.view addSubview: contentView];
	}
	return contentView;
}


#pragma mark UITableView delegates


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat height = 0.0;
	
	if (indexPath.section == 0) {
		height = 30.0;
	}
	else {
		height = 200.0;
	}
	
	return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO: need to define table cells.
	
	NSString* identity;
	UITableViewCell *cell = nil;
	
	if (indexPath.section == 0) {
		identity = @"TextInputCell0";
		cell = [tableView dequeueReusableCellWithIdentifier:identity];
		if (cell == nil) {
			//cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity] autorelease];
			UITextField *view = self.titleView;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			[cell addSubview:view];
		}
	}
	else {
		identity = @"TextInputCell1";
		cell = [tableView dequeueReusableCellWithIdentifier:identity];
		if (cell == nil) {
			//cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			UITextView *view = self.contentView;
			[cell addSubview:view];
		}
	}
	
	return cell;
}

- (void)dealloc {
	[titleView release];
	[contentView release];
	
    [super dealloc];
}


@end
