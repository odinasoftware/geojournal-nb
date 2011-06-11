//
//  AddMailRecipientController.m
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "AddMailRecipientController.h"
#import "GeoDatabase.h"
#import "GeoJournalHeaders.h"
#import "AddMailTo.h"
#import "MailRecipients.h"

#define MAIL_RECIPIENT_INDEX	0
//#define MAIL_INPUT_INDEX		1


@implementation AddMailRecipientController

@synthesize theTableView;
@synthesize mailRecipientArray;
@synthesize mailToController;

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
	
	UIBarButtonItem *editButton = [[UIBarButtonItem alloc]
									initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editMailto)];
	self.navigationItem.rightBarButtonItem = editButton;
	[editButton release];
	
	mailRecipientArray = [GeoDatabase sharedGeoDatabaseInstance].mailRecipientArray;
}

#pragma mark Table Editing
- (void)doneEditing
{
	[theTableView setEditing:NO animated:NO];
	UIBarButtonItem *editButton = [[UIBarButtonItem alloc]
								   initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editMailto)];
	self.navigationItem.rightBarButtonItem = editButton;
	[editButton release];
}

- (void)editMailto
{
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
	
	self.navigationItem.rightBarButtonItem = doneButton;
	
	[theTableView setEditing:YES animated:YES];
}

- (void)deleteMailToIndex:(NSInteger)index
{
	NSManagedObject *categoryToDelete = [self.mailRecipientArray objectAtIndex:index];
	[[GeoDatabase sharedGeoDatabaseInstance] deleteObject:categoryToDelete];
	//[managedObjectContext deleteObject:categoryToDelete];

	// Update the array and table view.
	[self.mailRecipientArray removeObjectAtIndex:index];

	// Commit the change.
	[[GeoDatabase sharedGeoDatabaseInstance] save];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	TRACE("%s, section: %d, row: %d\n", __func__, indexPath.section, indexPath.row);
	if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.row < [self.mailRecipientArray count]) {
		// remove this entry from database    
		[self deleteMailToIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
	
	if (indexPath.row < [self.mailRecipientArray count]) {
		style = UITableViewCellEditingStyleDelete;
	}
	return style;
}
#pragma mark -
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
	int c = 1;
	
	c = [mailRecipientArray count];
		
	return c+1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *str = nil;
	
	if (section == MAIL_RECIPIENT_INDEX) {
		str = @"Mail Recipients";
	}
	
	return str;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return @"The checkmarked recipient will be selected by the mail client.";
}


#pragma mark UITableView delegates

- (void)selectThisRowAndSave:(NSInteger)row
{
	int i = 0;
	for (MailRecipients *r in mailRecipientArray) {
		if (i == row) {
			[r setSelected:[NSNumber numberWithBool:YES]];
			
		}
		else {
			[r setSelected:[NSNumber numberWithBool:NO]];
		}
		++i;
	}
		
	[[GeoDatabase sharedGeoDatabaseInstance] save];
	[theTableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == [mailRecipientArray count]) {
		// Add more recipient
		mailToController = [[AddMailTo alloc] initWithNibName:@"AddMailTo" bundle:nil];
		[self.navigationController pushViewController:mailToController animated:YES];
	}	
	else if (indexPath.row < [mailRecipientArray count]) {
		[self selectThisRowAndSave:indexPath.row];
	}
	else {
		NSLog(@"%s, index error.", __func__);
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO: need to define table cells.
	
	NSString* identity = @"CategoryTypeCell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identity];
	
	if (cell == nil) {
		//cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity] autorelease];
	}
	
	int c = [mailRecipientArray count];
	if (indexPath.row < c) {
		MailRecipients *recipient = (MailRecipients*) [mailRecipientArray objectAtIndex:indexPath.row];
		cell.textLabel.text = recipient.mailto;

		if ([recipient.selected boolValue] == YES) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	else if (indexPath.row == c) {
		cell.textLabel.text = ADD_MAIL_RECIPIENT;	
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else {
		NSLog(@"%s, index error: %d", __func__, indexPath.row);
	}
	
	return cell;
}

- (void)viewDidAppear:(BOOL)animated
{
	if (mailToController && mailToController.saveResult == YES) {
		TRACE("%s\n", __func__);
		
		[self saveMailTo];
		[theTableView reloadData];
		mailToController.saveResult = NO;
	}
}

- (void)saveMailTo
{
	MailRecipients *recipients = [GeoDatabase sharedGeoDatabaseInstance].mailRecipient;
	
	if ([mailToController.textInputField.text length] > 0) {
		[recipients setMailto:mailToController.textInputField.text];
		[recipients setCreationDate:[NSDate date]];
		
		if ([self.mailRecipientArray count] == 0) {
			// set to default
			[recipients setSelected:[NSNumber numberWithBool:YES]];
		}
		[[GeoDatabase sharedGeoDatabaseInstance] save];
		[self.mailRecipientArray addObject:recipients];
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self.theTableView = nil;
	self.mailRecipientArray = nil;
	self.mailToController = nil; 
}


- (void)dealloc {
	[mailToController release];
	[theTableView release];
	[mailRecipientArray release];
	
    [super dealloc];
}


@end
