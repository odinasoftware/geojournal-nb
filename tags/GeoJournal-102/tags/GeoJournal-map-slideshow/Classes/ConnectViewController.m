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
#import "FBConnect/FBConnect.h"
#import "GeoJournalHeaders.h"
#import "GeoDatabase.h"

#define CONNECT_SECTIONS	2
#define MAIL_INDEX			0
#define FACEBOOK_INDEX		1

#define kConnectObjectKey	@"object"
#define kConnectHeaderKey	@"header"
#define kConnectFooterKey	@"footer"
#define kConnectRowsKey		@"rows"

@implementation ConnectViewController

@synthesize _tableView;
@synthesize connectObjectArray;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"ConnectTarget" ofType:@"plist"];
		connectObjectArray = [[NSArray alloc] initWithContentsOfFile:thePath];
    }
    return self;
}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark FACEBOOK 
- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	NSLog(@"User with id %lld logged in.", uid);
	[GeoSession sharedGeoSessionInstance].fbUID = uid;
	[self getUserName];
}

- (void)getUserName {
	NSString* fql = [[NSString alloc] initWithFormat:@"select name from user where uid == %qu", [GeoSession sharedGeoSessionInstance].fbUID];
	
	NSDictionary* params = [NSDictionary dictionaryWithObject:fql forKey:@"query"];
	[[FBRequest requestWithDelegate:self] call:@"facebook.fql.query" params:params];
}

- (void)request:(FBRequest*)request didLoad:(id)result {
	NSArray* users = result;
	NSDictionary* user = [users objectAtIndex:0];
	[GeoSession sharedGeoSessionInstance].fbUserName = [user objectForKey:@"name"];
	// Show user name
	NSLog(@"Query returned %@", [GeoSession sharedGeoSessionInstance].fbUserName);
	[self._tableView reloadData];
}


#pragma mark -
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
	/*
	int c = [categoryArray count];
	
	if (indexPath.row == self.numberOfCategory) {
		// Add more category
		addCategoryController = [[AddCategory alloc] initWithNibName:@"AddCategory" bundle:nil];
		addCategoryController.hidesBottomBarWhenPushed = YES;
		[self.navigationController pushViewController:addCategoryController animated:YES];
	}
	else if (indexPath.row < c) {
		journalViewController.categoryForView = [categoryArray objectAtIndex:indexPath.row];
		[self.navigationController pushViewController:journalViewController animated:YES];
	}
	else 
	{
		NSLog(@"%s, index error: %d", __func__, indexPath.row);
		//journalViewController.categoryForView = [categoryArray objectAtIndex:indexPath.row-c];
		//[self.navigationController pushViewController:journalViewController animated:YES];
	}
	 */
	if (indexPath.section == MAIL_INDEX) {
		AddMailRecipientController *controller = [[AddMailRecipientController alloc] initWithNibName:@"AddMailRecipient" bundle:nil];
		[self.navigationController pushViewController:controller animated:YES];
	}
	else if (indexPath.section == FACEBOOK_INDEX) {
		if ([GeoSession sharedGeoSessionInstance].fbUID > 0 && [GeoSession sharedGeoSessionInstance].fbUserName) {
			// already logged in. prompt to logout.
		}
		else {
			FBLoginDialog* dialog = [[[FBLoginDialog alloc] initWithSession:[GeoSession getFBSession:self]] autorelease];
			[dialog show];
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
	/*
	int c = [connectObjectArray count]; //[defaultCategory count];
	
	if (indexPath.section < c) {
		NSDictionary *dict = [connectObjectArray objectAtIndex:indexPath.section];
		NSString *name = [dict objectForKey:kConnectObjectKey];
		
		cell.textLabel.text = name;
	}
	*/
	/*
	if (indexPath.section == MAIL_INDEX) {
		NSDictionary *dict = [connectObjectArray objectAtIndex:indexPath.section];
		NSString *name = [dict objectForKey:kConnectObjectKey];
		
		cell.textLabel.text = name;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if (indexPath.section == FACEBOOK_INDEX) {
		CGRect frame = CGRectMake(20, 5, 150, 30);
		FBLoginButton* button = [[[FBLoginButton alloc] initWithFrame:frame] autorelease];
		[cell.contentView addSubview:button];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	*/
	if (indexPath.section == MAIL_INDEX) {
		NSDictionary *dict = [connectObjectArray objectAtIndex:indexPath.section];
		NSString *objectName = [dict objectForKey:kConnectObjectKey];
		NSString *r = [GeoDatabase sharedGeoDatabaseInstance].defaultRecipient;
		if (r) {
			NSString *format = [[NSString alloc] initWithFormat:@"%@ (%@)", objectName, r];
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
#pragma mark GENERAL


#pragma mark -
#pragma mark MEMORY MANAGEMENT
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self._tableView = nil;
	self.connectObjectArray = nil;
}


- (void)dealloc {
	[_tableView release];
	[connectObjectArray release];
	
    [super dealloc];
}


@end
