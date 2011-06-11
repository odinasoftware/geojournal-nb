//
//  JournalViewController.m
//  GeoJournal
//
//  Created by Jae Han on 7/10/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "JournalViewController.h"
#import "Category.h"
#import "GeoDatabase.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "TableCellView.h"
#import "GeoDefaults.h"
#import "JournalEntryViewController.h"

@implementation JournalViewController

@synthesize categoryForView;
@synthesize journalArray;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.navigationItem.title = categoryForView.name;
	self.hidesBottomBarWhenPushed = YES;
}

- (void)fetchJournalForCategory:(Category*)category 
{
	if (category == nil) {
		NSLog(@"%s, category object is null.", __func__);
		return;
	}
	
	self.journalArray = [category.contents allObjects];
	
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationItem.title = categoryForView.name;
	[self fetchJournalForCategory:self.categoryForView];
	[self.tableView reloadData];
	TRACE("%s, %d\n", __func__, [journalArray count]);
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

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
	self.categoryForView = nil;
	self.journalArray = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	TRACE("%s, %d\n", __func__, [journalArray count]);
    return [journalArray count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	NSString *imageLink = nil;
	BOOL reusableCell = NO;
	BOOL dontDoAnything = NO;
	TableCellView *imageRect = nil;
	UIImage *image = nil;
	UILabel *title = nil, *description=nil;
	static NSString *CellIdentifier = @"JournalCell";
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	else {
		reusableCell = YES;
	}
	
	Journal *journal = [journalArray objectAtIndex:indexPath.row];
	if (journal == nil) {
		NSLog(@"%s, journal is null.", __func__);
		return nil;
	}
	TRACE("%s, Journal entry:\n", __func__);
	TRACE("%s\n", [journal.title UTF8String]);
	TRACE("%s\n", [journal.text UTF8String]);
	TRACE("%s\n", [journal.audio UTF8String]);
	TRACE("%s, long:%f, lat: %f\n", [journal.address UTF8String], [journal.longitude floatValue], [journal.latitude floatValue]);
	TRACE("%s\n", [journal.picture UTF8String]);
	TRACE("\n");
	
	imageRect = (TableCellView*)[cell.contentView viewWithTag:MREADER_IMG_TAG];
	if (imageRect == nil) {
		imageRect = [[[TableCellView alloc] initWithFrame:CGRectMake(IMG_RECT_X, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT)] autorelease];
		imageRect.tag = MREADER_IMG_TAG;
		[imageRect setImageLink:NO_IMAGE_AVAIABLE];
	}
	
	title = (UILabel*)[cell.contentView viewWithTag:MREADER_TITLE_TAG];
	if (title == nil) {
		title = [[[UILabel alloc] initWithFrame:CGRectMake(TITLE_RECT_X, TITLE_RECT_Y, TITLE_RECT_WIDTH, TITLE_RECT_HEIGHT)] autorelease]; 
		title.tag = MREADER_TITLE_TAG;
		title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];//[UIFont systemFontOfSize:14.0]; 
		title.textColor = [UIColor blackColor]; 
		title.lineBreakMode = UILineBreakModeWordWrap; 
		title.numberOfLines = 2;
		//title.autoresizingMask = UIViewAutoresizingFlexibleWidth | 	UIViewAutoresizingFlexibleHeight; 
	}
	
	description = (UILabel*)[cell.contentView viewWithTag:MREADER_DESCRIPTION_TAG];
	if (description == nil) {
		description = [[[UILabel alloc] initWithFrame:CGRectMake(DESC_RECT_X, DESC_RECT_Y, DESC_RECT_WIDTH, DESC_RECT_HEIGHT)] autorelease];
		description.tag = MREADER_DESCRIPTION_TAG;
		description.font = [UIFont fontWithName:@"HelveticaNeue" size:12];//[UIFont systemFontOfSize:12.0];
		description.textColor = [UIColor grayColor];
		description.lineBreakMode = UILineBreakModeTailTruncation;
		description.numberOfLines = 4;
		//description.autoresizingMask = UIViewAutoresizingFlexibleWidth | 	UIViewAutoresizingFlexibleHeight; 
	}
	
	// 
	imageLink = [[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:journal.picture];
	if (imageLink != nil) {		
		// Image link is available.
		//			[storage addImage:image];
		
		
		if ([imageRect compareImageLink:imageLink] == NO) {
			// new image link is set
			if (([imageRect compareImageLink:DEFAULT_IMAGE] == NO) && (imageRect.image != nil)) 
				[imageRect.image release];
			image = [[UIImage alloc] initWithContentsOfFile:imageLink];
			if (image == nil) {
				NSLog(@"%s, %@ is null.", __func__, imageLink);
			}
			imageRect.image = image;
			[imageRect setImageLink:imageLink];
			if (reusableCell == NO)
				[cell.contentView addSubview:imageRect];
		}
		else {
			dontDoAnything = YES;
		}
		
	}
	else if ([imageRect compareImageLink:DEFAULT_IMAGE] == NO) {
		// The current image in the cell is not default image.
		// Change to default image.
		if (imageRect.image != nil)
			[imageRect.image release];
		imageRect.image = nil; //defaultBBCLogo;
		[imageRect setImageLink:DEFAULT_IMAGE];
		if (reusableCell == NO)
			[cell.contentView addSubview:imageRect];
	}
	else {
		dontDoAnything = YES;
	}
	
	NSString *text = journal.title;
	if ((title.text == nil) || 
		([title.text compare:text] != NSOrderedSame)) {
		title.text = text;
		//NSLog(@"tableView text: %@", title.text);
		if (reusableCell == NO)
			[cell.contentView addSubview:title];
	}
	
	NSString *descriptionText = journal.text;
	if ((description.text == nil) || 
		([description.text compare:descriptionText] != NSOrderedSame)) {
		description.text = descriptionText;
		if (reusableCell == NO)
			[cell.contentView addSubview:description];
	}
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    JournalEntryViewController *controller = [[JournalEntryViewController alloc] initWithNibName:@"JournalEntryView" bundle:nil];
	controller.entryForThisView = [journalArray objectAtIndex:indexPath.row];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)dealloc {
	[journalArray release];
	[categoryForView release];
    [super dealloc];
}


@end

