//
//  GeoSplitTableController.m
//  GeoJournal
//
//  Created by Jae Han on 10/18/11.
//  Copyright (c) 2011 Home. All rights reserved.
//
#import "GCategory.h"
#import "GeoDatabase.h"
#import "GeoJournalHeaders.h"
#import "GeoSplitTableController.h"
#import "GeoDefaults.h"
#import "DefaultCategory.h"

@implementation GeoSplitTableController

@synthesize popoverController, splitViewController, rootPopoverButtonItem;
@synthesize categoryArray;
@synthesize defaultCategory;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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

    TRACE_HERE;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self loadFromDatabase];
    self.contentSizeForViewInPopover = CGSizeMake(310.0, self.tableView.rowHeight*[self.categoryArray count]);
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.splitViewController = nil;
	self.rootPopoverButtonItem = nil;
    
    TRACE_HERE;
    /*
	self._journalView = nil;
	self.journalController = nil;
	
	[buttons removeAllObjects];
	
	self.categoryEditView = nil;
	self.tableView = nil;
	self.selectedCategory = nil;
	self.journalController = nil;
	self.defaultCategory = nil;
	self.buttonFrame = nil;
	
	self.selectionImage = nil;
	self.infoButtonImage = nil;
	self.buttons = nil;
	self.selectedColor = nil;
	self.listImage = nil;
	self.leftArrow = nil;
	self.rightArrow = nil;
	
	self.picasaIcon = nil;
	self.uploadSelectedIcon = nil;
	self.uploadNotSelectedIcon = nil;
	self.backgroundLabel = nil;
	self.backgroundLabel2 = nil;
    
	self.categoryLabel = nil;
    self.buttonView = nil;
    self.backgroundView = nil;
     */

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (GCategory*)getCategory:(NSString*)name
{
	GCategory *ret = nil;
	int n = 0;
	
	for (GCategory *c in categoryArray) {
		if ([c.name compare:name] == NSOrderedSame) {
			ret = c;
			break;
		}
		n++;
	}
	
	return ret;
}

- (void)addIntroEntry
{
	//if ([[GeoDefaults sharedGeoDefaultsInstance].testJournalCreated boolValue] == NO) {
	GCategory *chicago = [self getCategory:@"Daily Journal"];
	//NSString *path = [[NSBundle mainBundle] pathForResource:@"JournalTest" ofType:@"plist"];
	//NSMutableArray *testJournal = [[NSMutableArray alloc] initWithContentsOfFile:path];
	NSString *path = [[NSBundle mainBundle] pathForResource:@"intro" ofType:@"png"];
	NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
	path = [[NSBundle mainBundle] pathForResource:@"intro_small" ofType:@"png"];
	NSData *thumb = [[NSData alloc] initWithContentsOfFile:path];
	//path = [[NSBundle mainBundle] pathForResource:@"1074077865" ofType:@"aif"];
	//NSData *audioData = [[NSData alloc] initWithContentsOfFile:path];
	
	NSString *imageFileName = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:@".png"];
	NSString *thumbFileName = getThumbnailFilename(imageFileName);
	//NSString *audioFileName = [[GeoDefaults sharedGeoDefaultsInstance] getUniqueFilenameWithExt:@".aif"];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	
	[manager createFileAtPath:imageFileName contents:imageData attributes:nil];
	[manager createFileAtPath:thumbFileName contents:thumb attributes:nil];
	//[manager createFileAtPath:audioFileName contents:audioData attributes:nil];
	
	[imageData release];
	//[audioData release];
	[thumb release];
	[thumbFileName release];
	
	//for (NSDictionary *d in testJournal) {
    Journal *journal = [GeoDatabase sharedGeoDatabaseInstance].journalEntity; 
    
    //[journal setAudio:[audioFileName lastPathComponent]];
    //TRACE("Audio: %s\n", [audioFileName UTF8String]);
    
    [journal setPicture:[imageFileName lastPathComponent]];
    TRACE("Picture: %s\n", [imageFileName UTF8String]);
    
	[journal setText:@"Thank you for choosing iGeoJournal. iGeoJournal is your one stop application. We are planning many updates ahead. The first upcoming update is synching with Picasa web album. For more detailed information, please visit http://odinasoftware.com.\n\nUse iGeoJournal for your travel, your daily journal, or your restaurant review, iGeoJournal will be perfect companion for you. Enjoy!"]; 
	[journal setTitle:@"Welcome to iGeoJournal."];
    
    [journal setCreationDate:[NSDate date]];
    
    //[journal setLongitude:(NSNumber*)[d objectForKey:@"longitude"]];
    //[journal setLatitude:(NSNumber*)[d objectForKey:@"latitude"]];
    
    //[journal setAddress:(NSString*)[d objectForKey:@"address"]];
    
    [chicago addContentsObject:journal];
	//}
	[[GeoDatabase sharedGeoDatabaseInstance] save];
	//[GeoDefaults sharedGeoDefaultsInstance].testJournalCreated = [NSNumber numberWithBool:YES];
	//}
	
	
}

- (void)verifyDefaultCategories
{
	DefaultCategory *dc = nil;
	
	// only do that for the first run. And what to do for the already installed user.
	NSInteger initDone = [[GeoDefaults sharedGeoDefaultsInstance].defaultInitDone intValue];
	
	if (initDone == 0) {
		for (NSString *categoryName in defaultCategory) {
			dc = nil;
			for (DefaultCategory *c in self.categoryArray) {
				if ([categoryName compare:c.name] == NSOrderedSame) {
					// found one, don't need to add.
					dc = c;
					break;
				}
			}
			if (dc == nil) {
				// don't have one, need to add it.
				DefaultCategory *category = [GeoDatabase sharedGeoDatabaseInstance].defaultCategoryEntity; 
				
				[category setName:categoryName];
				
				[[GeoDatabase sharedGeoDatabaseInstance] save];
				[self.categoryArray addObject:category];
			}
		}
		
		[self addIntroEntry];
        [[GeoDefaults sharedGeoDefaultsInstance] dbInitDone];
	}
}

- (void)loadFromDatabase
{
	// Load from the category database
	self.categoryArray = [GeoDatabase sharedGeoDatabaseInstance].categoryArray;
	
	[self verifyDefaultCategories];	
}


#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController:(UIPopoverController*)pc {
    TRACE_HERE;
    // Keep references to the popover controller and the popover button, and tell the detail view controller to show the button.
    barButtonItem.title = @"Root View Controller";
    self.popoverController = pc;
    self.rootPopoverButtonItem = barButtonItem;
    UIViewController <SubstitutableDetailViewController> *detailViewController = [splitViewController.viewControllers objectAtIndex:1];
    [detailViewController showRootPopoverButtonItem:rootPopoverButtonItem];
}


- (void)splitViewController:(UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    TRACE_HERE;
    // Nil out references to the popover controller and the popover button, and tell the detail view controller to hide the button.
    UIViewController <SubstitutableDetailViewController> *detailViewController = [splitViewController.viewControllers objectAtIndex:1];
    [detailViewController invalidateRootPopoverButtonItem:rootPopoverButtonItem];
    self.popoverController = nil;
    self.rootPopoverButtonItem = nil;
}


#pragma mark -


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.categoryArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RootViewControllerCellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    DefaultCategory *c = [self.categoryArray objectAtIndex:indexPath.row];
    cell.textLabel.text = c.name;
    
    return cell;
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

- (void)dealloc {
    /*
	[leftArrow release];
	[rightArrow release];
	[categoryLabel release];
	[backgroundLabel2 release];
	[backgroundLabel release];
	[uploadSelectedIcon release];
	[uploadNotSelectedIcon release];
	[picasaIcon release];
	[editCategoryController release];
	[categoryEditView release];
	[tableView release];
	[journalController release];
	[_dateArray release];
	[defaultImage release];
	[journalArray release];
	[selectedCategory release];
	[_journalView release];
	
	[listImage release];
	[buttons release];
     */
	[categoryArray release];
    [defaultCategory release];
    /*
	[selectedCategory release];
	[journalController release];
	
	[buttonFrame release];
    
	[selectedColor release];
	[infoButtonImage release];
	[selectionImage release];
    [buttonView release];
    [backgroundView release];
     */
	
	//AudioServicesDisposeSystemSoundID (soundFileObject);
	//CFRelease (soundFileURLRef);
	
    [super dealloc];
}


@end


