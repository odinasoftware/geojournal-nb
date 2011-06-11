//
//  SearchController.m
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "SearchController.h"
#import "GeoJournalHeaders.h"
#import "Category.h"
#import "GeoDatabase.h"
#import "GeoDefaults.h"
#import "Journal.h"
#import "JournalEntryViewController.h"

#define	TITLE_INDEX			0
#define CONTENT_INDEX		1
#define LOCATION_INDEX		2
#define ENTIRE_INDEX		3

#define SEARCH_TITLE_RECT_X					10.0
#define SEARCH_TITLE_RECT_Y					0.0
#define SEARCH_TITLE_RECT_WIDTH				240	
#define SEARCH_TITLE_RECT_HEIGHT			40.0


#define DEFAULT_RESULT_COUNT		10
#define SEARCH_CONTENT_VIEW_TAG		1

@implementation SearchController

@synthesize _tableView;
@synthesize _searchBar;
@synthesize searchController;
@synthesize categoryArray;
@synthesize searchResult;
@synthesize searchResultIndex;
@synthesize _journalView;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	TRACE_HERE;
	self.navigationItem.title = @"Search";
	searchController = [[UISearchDisplayController alloc]
					   initWithSearchBar:self._searchBar contentsController:self];
	searchController.searchResultsDataSource = self;
	searchController.searchResultsDelegate = self;
	NSArray *scopeButtonTitles = [[NSArray alloc] initWithObjects:@"Title", @"Content", @"Location", @"Entire", nil];
	self._searchBar.scopeButtonTitles = scopeButtonTitles;
	self._searchBar.selectedScopeButtonIndex = [[GeoDefaults sharedGeoDefaultsInstance].searchIndex intValue];

	[scopeButtonTitles release];
	self.categoryArray = [GeoDatabase sharedGeoDatabaseInstance].categoryArray;
	self.searchResult = [[NSMutableArray alloc] initWithCapacity:DEFAULT_RESULT_COUNT];
	self.searchResultIndex = [[NSMutableArray alloc] initWithCapacity:DEFAULT_RESULT_COUNT];
}

- (void)viewDidAppear:(BOOL)animated
{
	TRACE_HERE;
	//self.navigationController.navigationBarHidden = YES;
	NSString *s = [GeoDefaults sharedGeoDefaultsInstance].searchString;
	if ([s length] > 0) {
		
		[self search:self._searchBar.selectedScopeButtonIndex withString:s];
		self._searchBar.text = s;
		self.searchController.active = YES;
	}
}


- (void)viewDidDisappear:(BOOL)animated
{
	TRACE("%s, %s\n", __func__, [self._searchBar.text UTF8String]);
	[GeoDefaults sharedGeoDefaultsInstance].searchIndex = [NSNumber numberWithInt:self._searchBar.selectedScopeButtonIndex];
	[GeoDefaults sharedGeoDefaultsInstance].searchString = self._searchBar.text;
	[[GeoDefaults sharedGeoDefaultsInstance] saveSerarchSettings];
}

#pragma mark SEARCH IMPLEMENTATION

- (void)search:(int)index withString:(NSString*)string 
{
	BOOL found = NO;
	NSRange range;
	NSArray *array = nil;
	
	TRACE("%s, index: %d, str: %s\n", __func__, index, [string UTF8String]);
	[self.searchResult removeAllObjects];
	[self.searchResultIndex removeAllObjects];
	
	for (Category *c in self.categoryArray) {
		array = [[GeoDatabase sharedGeoDatabaseInstance] journalByCategory:c];
		for (Journal *j in array) {
			found = NO;
			if ([j.title length] > 0 && (index == TITLE_INDEX || index == ENTIRE_INDEX)) { // title comparision
				range = [j.title rangeOfString:string options:NSCaseInsensitiveSearch];
				if (range.location != NSNotFound) {
					[self.searchResult addObject:j];
					[self.searchResultIndex addObject:[NSNumber numberWithInt:TITLE_INDEX]];
					found = YES;
					//TRACE("%s, %s, %d\n", __func__, [j.title UTF8String], TITLE_INDEX);
				}
			}
			
			if ([j.address length] > 0 && (index == LOCATION_INDEX || (index == ENTIRE_INDEX && found == NO))) {
				range = [j.address rangeOfString:string options:NSCaseInsensitiveSearch];
				if (range.location != NSNotFound) {
					[self.searchResult addObject:j];
					[self.searchResultIndex addObject:[NSNumber numberWithInt:LOCATION_INDEX]];
					found = YES;
					//TRACE("%s, %s, %d\n", __func__, [j.address UTF8String], LOCATION_INDEX);
				}
			}
			
			if ([j.text length] > 0 && (index == CONTENT_INDEX || (index == ENTIRE_INDEX && found == NO))) {
				range = [j.text rangeOfString:string options:NSCaseInsensitiveSearch];
				if (range.location != NSNotFound) {
					[self.searchResult addObject:j];
					[self.searchResultIndex addObject:[NSNumber numberWithInt:CONTENT_INDEX]];
					found = YES;
					//TRACE("%s, %s, %d\n", __func__, [j.text UTF8String], CONTENT_INDEX);
				}
			}
		}
	}
}

#pragma mark -
#pragma mark SEARCH BAR delegates
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	// TODO: Implement efficient search engine.
	TRACE("%s, %s\n", __func__, [searchText UTF8String]);
	
	if ([searchText length] > 0) {
		[self search:searchBar.selectedScopeButtonIndex withString:searchText];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self._searchBar resignFirstResponder];
	TRACE_HERE;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self._searchBar resignFirstResponder];
	[self.searchResult removeAllObjects];
	[self.searchResultIndex removeAllObjects];

	TRACE_HERE;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	TRACE_HERE;
	return 1;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// TODO: Get the default category and categories from database
	// Define NSArray for default category and fetch from database rest.
	TRACE("%s, %d\n", __func__, [self.searchResult count]);
	return [self.searchResult count];
}


#pragma mark UITableView delegates

- (NSString*)getStringFromStringResult:(int)index
{
	NSString *result = nil;
	Journal *j = [self.searchResult objectAtIndex:index];
	NSNumber *n = [self.searchResultIndex objectAtIndex:index];
	
	if (j && n) {
		switch ([n intValue]) {
			case TITLE_INDEX:
				result = j.title;
				break;
			case CONTENT_INDEX:
				result = j.text;
				break;
			case LOCATION_INDEX:
				result = j.address;
				break;
			default:
				break;
		}
	}
	
	TRACE("%s, %p, %s, %d\n", __func__, j, [j.title UTF8String], index);
	return result;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	TRACE("%s, %p\n", __func__, self.navigationController);
	if (indexPath.row < [self.searchResult count]) {
		JournalEntryViewController *controller = [[JournalEntryViewController alloc] initWithNibName:@"JournalEntryView" bundle:nil];
		controller.showToolbar = NO;
		controller.entryForThisView = [self.searchResult objectAtIndex:indexPath.row];
		controller.hidesBottomBarWhenPushed = YES;
		self.navigationController.navigationBarHidden = NO;
		[self.navigationController pushViewController:controller animated:YES];
		self._journalView = controller;
		[controller release];
		
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO: need to define table cells.
	/*
	NSString* identity = @"MailToCell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identity];
	
	if (cell == nil) {
		//cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity] autorelease];
		UITextField *textField = self.textInputField;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell addSubview:textField];
	}
	
	
	 
	
	//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	*/
	
	TRACE("%s, section: %d, row: %d\n", __func__, indexPath.section, indexPath.row);
	NSString* identity = @"SearchCell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identity];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
	}
	
	int c = [self.searchResult count]; 
	if (indexPath.row < c) {
		
		UILabel *textLabel = (UILabel*) [cell.contentView viewWithTag:SEARCH_CONTENT_VIEW_TAG];
		if (textLabel == nil) {
			textLabel = [[UILabel alloc] initWithFrame:CGRectMake(SEARCH_TITLE_RECT_X, SEARCH_TITLE_RECT_Y, SEARCH_TITLE_RECT_WIDTH, SEARCH_TITLE_RECT_HEIGHT)];
			textLabel.tag = SEARCH_CONTENT_VIEW_TAG;
			textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
			textLabel.textColor = [UIColor blackColor];
		}
		
		textLabel.text = [self getStringFromStringResult:indexPath.row];
		[cell.contentView addSubview:textLabel];		
	}
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	 
	return cell;
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
	self._tableView = nil;
	self._searchBar = nil;
	self._journalView = nil;
	TRACE_HERE;
}


- (void)dealloc {
	TRACE_HERE;
	[_journalView release];
	[searchController release];
	[_tableView release];
	[_searchBar release];
	[categoryArray release];
	[searchResult release];
	[searchResultIndex release];
	
    [super dealloc];
}


@end
