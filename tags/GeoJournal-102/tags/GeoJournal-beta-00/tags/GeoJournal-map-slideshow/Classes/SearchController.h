//
//  SearchController.h
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SearchController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate> {
	IBOutlet UISearchBar	*_searchBar;
	IBOutlet UITableView	*_tableView;
	
	UISearchDisplayController	*searchController;
}

@property (nonatomic, retain) UISearchBar *_searchBar;
@property (nonatomic, retain) UITableView *_tableView;
@property (nonatomic, retain) UISearchDisplayController *searchController;

@end
