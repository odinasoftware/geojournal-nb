//
//  SearchController.m
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "SearchController.h"


@implementation SearchController

@synthesize _tableView;
@synthesize _searchBar;
@synthesize searchController;

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
	
	searchController = [[UISearchDisplayController alloc]
					   initWithSearchBar:self._searchBar contentsController:self];
	searchController.searchResultsDataSource = self;
	searchController.searchResultsDelegate = self;
	NSArray *scopeButtonTitles = [[NSArray alloc] initWithObjects:@"Title", @"Content", @"Location", @"Entire", nil];
	self._searchBar.scopeButtonTitles = scopeButtonTitles;
	[scopeButtonTitles release];
}

#pragma mark SEARCH BAR delegates
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	// TODO: Implement efficient search engine.
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self._searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self._searchBar resignFirstResponder];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 0;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// TODO: Get the default category and categories from database
	// Define NSArray for default category and fetch from database rest.
	
	return 0;
}


#pragma mark UITableView delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
	return nil;
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
}


- (void)dealloc {
	[searchController release];
	[_tableView release];
	[_searchBar release];
	
    [super dealloc];
}


@end
