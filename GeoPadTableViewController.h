//
//  GeoPadTableViewController.h
//  GeoJournal
//
//  Created by Jae Han on 10/28/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GeoSplitTableController.h"
#import "NoteViewController.h"

@class GCategory;
@class PadEntryViewController;

@interface GeoPadTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, SubstitutableDetailViewController, ChangeCategory>
{
    //UIToolbar                   *toolbar;
    UITableView                 *tableView;
    NSArray                     *journalArray;
    NSMutableArray              *_dateArray;
    //UILabel                     *titleLable;
    NSArray                     *defaultCategory;
    NSMutableArray              *categoryArray;
    GCategory                   *selectedCategory;
    PadEntryViewController      *_journalView;
      
    // Toobar support   
    UIBarButtonItem             *categoryBar;
    UIBarButtonItem             *searchBar;
    UIBarButtonItem             *settingBar;
    UIBarButtonItem             *composeBar;
    UIBarButtonItem             *viewsBar;
    UILabel                     *titleLabel;
}

//@property (nonatomic, retain)   IBOutlet    UIToolbar       *toolbar;
@property (nonatomic, retain)   IBOutlet    UITableView     *tableView;
//@property (nonatomic, retain)   IBOutlet    UILabel         *titleLabel;

@property (nonatomic, retain)   NSArray                     *journalArray;
@property (nonatomic, retain)	NSMutableArray				*_dateArray;
@property (nonatomic, retain)	NSArray						*defaultCategory;
@property (nonatomic, retain)	NSMutableArray				*categoryArray;
@property (nonatomic, retain)	GCategory					*selectedCategory;
@property (nonatomic, retain)   PadEntryViewController      *_journalView;

@property (nonatomic, retain)   IBOutlet    UIBarButtonItem             *categoryBar;
@property (nonatomic, retain)   IBOutlet    UIBarButtonItem             *searchBar;
@property (nonatomic, retain)   IBOutlet    UIBarButtonItem             *settingBar;
@property (nonatomic, retain)   IBOutlet    UIBarButtonItem             *composeBar;
@property (nonatomic, retain)   IBOutlet    UIBarButtonItem             *viewsBar;
@property (nonatomic, retain)   IBOutlet    UILabel                     *titleLabel;


- (void)fetchJournalForCategory:(GCategory*)category ;
- (void)loadFromDatabase;
- (void)verifyDefaultCategories;
- (void)addIntroEntry;
- (GCategory*)getCategory:(NSString*)name;
- (void)fetchJournalForCategory:(GCategory*)category; 
- (void)generateDateArray;
- (void)showPopover:(id)sender;
- (void)reloadFetchedResults:(NSNotification*)note;

@end
