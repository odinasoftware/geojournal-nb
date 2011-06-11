//
//  SearchController.h
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JournalEntryViewController;

@interface SearchController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate> {
	IBOutlet UISearchBar		*_searchBar;
	IBOutlet UITableView		*_tableView;
	
	NSMutableArray				*categoryArray;
	UISearchDisplayController	*searchController;
	NSMutableArray				*searchResult;
	NSMutableArray				*searchResultIndex;
	
	@private
	JournalEntryViewController	*_journalView;
}

@property (nonatomic, retain) NSMutableArray				*categoryArray;
@property (nonatomic, retain) NSMutableArray				*searchResult;
@property (nonatomic, retain) NSMutableArray				*searchResultIndex;
@property (nonatomic, retain) UISearchBar					*_searchBar;
@property (nonatomic, retain) UITableView					*_tableView;
@property (nonatomic, retain) UISearchDisplayController		*searchController;
@property (nonatomic, retain) JournalEntryViewController	*_journalView;

- (void)search:(int)index withString:(NSString*)string;

@end
