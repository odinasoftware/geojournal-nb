//
//  ConnectViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "ConnectViewController.h"
#import "AddMailRecipientController.h"
#import "GeoSession.h"
#import "FBConnect.h"
#import "GeoJournalHeaders.h"
#import "GeoDatabase.h"
#import "FacebookConnect.h"

#define CONNECT_SECTIONS	2
#define MAIL_INDEX			0
#define FACEBOOK_INDEX		1

#define kConnectObjectKey	@"object"
#define kConnectHeaderKey	@"header"
#define kConnectFooterKey	@"footer"
#define kConnectRowsKey		@"rows"

extern Boolean testReachability();

@implementation ConnectViewController

@synthesize _tableView;
@synthesize connectObjectArray;

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
	TRACE_HERE;
    [super viewDidLoad];
	
	NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"ConnectTarget" ofType:@"plist"];
	connectObjectArray = [[NSArray alloc] initWithContentsOfFile:thePath];

	self.tabBarController.tabBar.selectedItem.title = @"Connect";
	self.navigationItem.title = @"Connect";
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	TRACE_HERE;
	return [connectObjectArray count];
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// TODO: Get the default category and categories from database
	// Define NSArray for default category and fetch from database rest.
	TRACE_HERE;
	NSDictionary *dict = [connectObjectArray objectAtIndex:section];
	NSNumber *c = (NSNumber*)[dict objectForKey:kConnectRowsKey];
	return [c intValue];
}

/*
In tableView:didSelectRowAtIndexPath: you should always deselect the currently selected row.
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == MAIL_INDEX) {
		AddMailRecipientController *controller = [[AddMailRecipientController alloc] initWithNibName:@"AddMailRecipient" bundle:nil];
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else if (indexPath.section == FACEBOOK_INDEX) {
		if (testReachability() == false) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook Connect Warning" message:@"Internet connection is not available. We cannot connect to Facebook. Please check your Internet connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
		else {

			if ([GeoSession sharedGeoSessionInstance].fbUID > 0 /*&& [GeoSession sharedGeoSessionInstance].fbUserName*/) {
				// already logged in. prompt to logout.
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook logout" message:@"Do you want to logout from your Facebook account?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
				[alert show];
				[alert release];
			}
			else {
				[[GeoSession sharedGeoSessionInstance] getExtendedPermission:nil];
			}
		}
	}
	else {
		NSLog(@"%s, index error.", __func__);
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO: need to define table cells.
	
	NSString* identity = @"ConnectCell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identity];
	
	TRACE("%s\n", __func__);
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
	}
	
	if (indexPath.section == MAIL_INDEX) {
		NSDictionary *dict = [connectObjectArray objectAtIndex:indexPath.section];
		NSString *objectName = [dict objectForKey:kConnectObjectKey];
		NSString *r = [GeoDatabase sharedGeoDatabaseInstance].defaultRecipient;
		if (r) {
			NSString *format = [[NSString alloc] initWithFormat:@"%@", r];
			cell.textLabel.text = format;
			[format release];
		}
		else if ([[GeoDatabase sharedGeoDatabaseInstance].mailRecipientArray count] == 0) {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (No recipient setup)", objectName];
			cell.textLabel.text = format;
			[format release];
		}
		else {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (No default recipient set)", objectName];
			cell.textLabel.text = format;
			[format release];
		}

		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if (indexPath.section == FACEBOOK_INDEX) {
		NSDictionary *dict = [connectObjectArray objectAtIndex:indexPath.section];
		NSString *objectName = [dict objectForKey:kConnectObjectKey];

		if ([GeoSession sharedGeoSessionInstance].fbUserName) {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (%@)", objectName, [GeoSession sharedGeoSessionInstance].fbUserName];
			cell.textLabel.text = format;
			[format release];
		}
		else if ([GeoSession sharedGeoSessionInstance].fbUID && [[GeoSession sharedGeoSessionInstance].facebook isSessionValid]) {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (Logged in)", objectName];
			cell.textLabel.text = format;
			[format release];
		}
		else {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (User is not logged in)", objectName];
			cell.textLabel.text = format;
			[format release];
		}

		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else {
		NSLog(@"%s, index error: %d", __func__, indexPath.row);
	}
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSDictionary *dict = [connectObjectArray objectAtIndex:section];
	NSString *header = (NSString*) [dict objectForKey:kConnectHeaderKey];
	return header;
}
		
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	NSDictionary *dict = [connectObjectArray objectAtIndex:section];
	NSString *footer = (NSString*) [dict objectForKey:kConnectFooterKey];
	return footer;	
}

#pragma mark CALLBACK_API
- (void)fbUserDidLogin
{
	TRACE("%s\n", __func__);
	[self._tableView reloadData];
}

#pragma mark -

#pragma mark ALERTVIEW delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0:
			break;
		case 1:
			[[GeoSession sharedGeoSessionInstance] logoutFBSessionWithNotification:YES];
			break;
		case 2:
			
			break;
		default:
			NSLog(@"%s, index error: %d", __func__, buttonIndex);
	}
}

#pragma mark -
#pragma mark GENERAL


#pragma mark -
#pragma mark MEMORY MANAGEMENT
- (void)didReceiveMemoryWarning {
	TRACE_HERE;
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	TRACE_HERE;
	self.connectObjectArray = nil;
	self._tableView = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
	[self._tableView reloadData];
}

- (void)dealloc {
	TRACE_HERE;
	[_tableView release];
	[connectObjectArray release];
	
    [super dealloc];
}


@end
