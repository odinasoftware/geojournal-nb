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

extern NSString *getPrinterableDate(NSDate *date, NSInteger *day);
extern NSString *getThumbnailFilename(NSString *filename); 

void GET_COORD_IN_PROPORTION(CGSize size, UIImage *image, float *atX, float *atY) {
	
	if (image.size.width > image.size.height) { // Landscape  
		*atX = size.width; 
		*atY = image.size.height * (size.width / image.size.width); 
		TRACE("%s, original: w: %f, h: %f, landscape y: %f\n", __func__, image.size.width, image.size.height, *atY);
	}	
	else { // Portrait 
		*atX = image.size.width * (size.height / image.size.height); 
		*atY = size.height; 
		TRACE("%s, original: w: %f, h: %f, portrait x: %f\n", __func__, image.size.width, image.size.height, *atX);
	} 
}

@implementation DateIndex

@synthesize dateString;
@synthesize index;

- (void)dealloc
{
	[dateString release];
	[super dealloc];
}

@end


@implementation JournalViewController

@synthesize defaultImage;
@synthesize categoryForView;
@synthesize journalArray;
@synthesize _dateArray;
@synthesize isCategoryChanged;
@synthesize _journalView;


/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		self.defaultImage = [UIImage imageNamed:@"journal-image-background.png"];
		NSMutableArray *array = [[NSMutableArray alloc] init];
		self._dateArray = array;
		[array release];
		needToReload = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.navigationItem.title = categoryForView.name;
	
	self.tabBarController.tabBar.selectedItem.title = @"Journal";

	TRACE("%s, %p\n", __func__, self);
	[self fetchJournalForCategory:self.categoryForView];
}

- (void)generateDateArray
{
	NSInteger current = -1;
	NSInteger day;
	NSString *dateString;
	int i = 0;
	
	[self._dateArray removeAllObjects];
	for (Journal *j in self.journalArray) {
		dateString = getPrinterableDate(j.creationDate, &day);
		if (current != day) {
			DateIndex *index = [[DateIndex alloc] init];
			index.dateString = dateString;
			index.index = i;
			[self._dateArray addObject:(id)index];
			current = day;
			[index release];
		}
		++i;
	}
}

- (void)fetchJournalForCategory:(Category*)category 
{
	if (category == nil) {
		NSLog(@"%s, category object is null.", __func__);
		return;
	}
	
	self.journalArray = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:category];
	TRACE("%s, %s, %d\n", __func__, [category.name UTF8String], [self.journalArray count]);
	
	[self generateDateArray];
}

- (void)setReload:(BOOL)reload 
{
	needToReload = reload;
}
/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	TRACE("%s, %d\n", __func__, [journalArray count]);
	
}
*/

- (void)viewDidAppear:(BOOL)animated {
	TRACE_HERE;
    [super viewDidAppear:animated];
	
	if ([GeoDefaults sharedGeoDefaultsInstance].levelRestored == NO) {
		[self restoreLevel];
	}
	else {
		[GeoDefaults sharedGeoDefaultsInstance].thirdLevel = -1;
		if (self.isCategoryChanged == YES) {
			self.navigationItem.title = categoryForView.name;			
			[self fetchJournalForCategory:self.categoryForView];
			
			self.isCategoryChanged = NO;
			[(UITableView*)self.view reloadData];
		}
		else if (needToReload == YES) {
			[self generateDateArray];
			[(UITableView*)self.view reloadData];
			needToReload = NO;
		}
			
	}
}

- (void)restoreLevel
{
	int index = [GeoDefaults sharedGeoDefaultsInstance].thirdLevel;
	if (index > -1) {
		JournalEntryViewController *controller = [[JournalEntryViewController alloc] initWithNibName:@"JournalEntryView" bundle:nil];
		controller.entryForThisView = [journalArray objectAtIndex:index];
		[self.navigationController pushViewController:controller animated:NO];
		self._journalView = controller;
		[controller release];
	}	
	[GeoDefaults sharedGeoDefaultsInstance].levelRestored = YES;
}

- (void)reloadJournalArray
{	
	self.journalArray = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:self.categoryForView];
	TRACE("%s, %d\n", __func__, [self.journalArray count]);
}
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	//[GeoDefaults sharedGeoDefaultsInstance].secondLevel = -1;
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
	TRACE_HERE;
	self._journalView = nil;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self._dateArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title = nil;
	
	if (section < [self._dateArray count]) {
		DateIndex *current = [self._dateArray objectAtIndex:section];
		title = current.dateString;
	}
	
	return title;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int count = 0;
	
	TRACE("%s, %d\n", __func__, [journalArray count]);
	int c = [self._dateArray count];
	if (section >= c) {
		NSLog(@"%s, index error: %d", __func__, section);
		return 0;
	}
	
	DateIndex *current = [self._dateArray objectAtIndex:section];
	if (section == c-1) {
		// last index
		count = [self.journalArray count] - current.index;
	}
	else if (section < c-1) {
		DateIndex *next = [self._dateArray objectAtIndex:section+1];
		count = next.index - current.index; 
	}
	else {
		NSLog(@"%s, index error: %d", __func__, section);
		return 0;
	}
	
    return count;
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
	
	if (indexPath.section >= [self._dateArray count]) {
		NSLog(@"%s, index error: %d", __func__, indexPath.section);
		return nil;
	}
	DateIndex *current = [self._dateArray objectAtIndex:indexPath.section];
	int actualIndex = current.index + indexPath.row;
	Journal *journal = [journalArray objectAtIndex:actualIndex];
	//TRACE("%s, section: %d, row: %d, actual: %d\n", __func__, indexPath.section, indexPath.row, actualIndex);
	if (journal == nil) {
		NSLog(@"%s, journal is null.", __func__);
		return nil;
	}
	/*
	TRACE("%s, Journal entry:\n", __func__);
	TRACE("%s\n", [journal.title UTF8String]);
	TRACE("%s\n", [journal.text UTF8String]);
	TRACE("%s\n", [journal.audio UTF8String]);
	TRACE("%s, long:%f, lat: %f\n", [journal.address UTF8String], [journal.longitude floatValue], [journal.latitude floatValue]);
	TRACE("%s\n", [journal.picture UTF8String]);
	TRACE("\n");
	 */
	
#ifdef ADD_BACKGROUND
	UIImageView *background = (UIImageView*) [cell.contentView viewWithTag:MREADER_BACKGROUND_TAG];
	if (background == nil) {
		background = [[[UIImageView alloc] initWithFrame:CGRectMake(BACK_RECT_X, BACK_RECT_Y, BACK_RECT_WIDTH, BACK_RECT_HEIGHT)] autorelease];
		background.image = self.defaultImage;
		background.tag = MREADER_BACKGROUND_TAG;
		[cell.contentView addSubview:background];
	}
#endif
	
	imageRect = (TableCellView*)[cell.contentView viewWithTag:MREADER_IMG_TAG];
	if (imageRect == nil) {
		imageRect = [[[TableCellView alloc] initWithFrame:CGRectMake(IMG_RECT_X, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT)] autorelease];
		imageRect.image = nil; 
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
		title.numberOfLines = 1;
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
		NSString *thumb = getThumbnailFilename(imageLink);
		if ([[NSFileManager defaultManager] fileExistsAtPath:thumb] == YES) {
			imageLink = thumb;
		}
		[imageLink retain];
		[thumb release];
	}
	
	if (imageLink != nil) {		
		// Image link is available.
		//			[storage addImage:image];
		
		
		if ([imageRect compareImageLink:imageLink] == NO) {
			// new image link is set
			if (([imageRect compareImageLink:DEFAULT_IMAGE] == NO) && (imageRect.image != nil)) {
				imageRect.image = nil;
			}
			NSData *data = [[NSData alloc] initWithContentsOfFile:imageLink];
			TRACE("%s, %s, %d\n", __func__, [imageLink UTF8String], [data length]);
			//image = [[UIImage alloc] initWithContentsOfFile:imageLink];
			image = [[UIImage alloc] initWithData:data];
			if (image == nil) {
				NSLog(@"%s, %@ is null.", __func__, imageLink);
			}
			imageRect.image = image;
						
			float x, y, move_x, move_y;
		
			imageRect.frame = CGRectMake(IMG_RECT_X, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT);
			GET_COORD_IN_PROPORTION(imageRect.frame.size, imageRect.image, &x, &y);
			move_x = x - imageRect.frame.size.width;
			move_y = y - imageRect.frame.size.height;
			move_x = MAKE_CENTER(move_x);
			move_y = MAKE_CENTER(move_y);
			// TODO: make them center
			TRACE("%s, image: w: %f, h: %f\n", __func__, image.size.width, image.size.height);
			TRACE("%s, move_x: %f, move_y: %f x: %f, y: %f\n", __func__, move_x, move_y, x, y);
			imageRect.frame = CGRectMake(imageRect.frame.origin.x+move_x, imageRect.frame.origin.y+move_y, x, y);
			 
			[imageRect setImageLink:imageLink];
			if (reusableCell == NO)
				[cell.contentView addSubview:imageRect];
			[data release];
			[image release];
			[imageLink release];
		}
		else {
			dontDoAnything = YES;
		}
		
	}
	else if ([imageRect compareImageLink:DEFAULT_IMAGE] == NO) {
		// The current image in the cell is not default image.
		// Change to default image.
		if (imageRect.image != nil) {
			imageRect.image = nil;
		}
		imageRect.frame = CGRectMake(IMG_RECT_X, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT);
		imageRect.image = self.defaultImage;
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
	self._journalView = controller;
	[controller release];
	
	if (indexPath.section >= [self._dateArray count]) {
		NSLog(@"%s, index error: %d", __func__, indexPath.section);
		return;
	}
	DateIndex *current = [self._dateArray objectAtIndex:indexPath.section];
	int actualIndex = current.index + indexPath.row;

	self._journalView.showToolbar = YES;
	self._journalView.entryForThisView = [journalArray objectAtIndex:actualIndex];
	self._journalView._parent = self;
	self._journalView.hidesBottomBarWhenPushed = YES;
	self._journalView.indexForThis = actualIndex;
	[GeoDefaults sharedGeoDefaultsInstance].thirdLevel = indexPath.row;
	[self.navigationController pushViewController:self._journalView animated:YES];
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
	[_dateArray release];
	[defaultImage release];
	[journalArray release];
	[categoryForView release];
	[_journalView release];
    [super dealloc];
}


@end

