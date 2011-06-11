//
//  JournalViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/10/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Category;

@interface JournalViewController : UITableViewController {
	Category			*categoryForView;
	NSArray			*journalArray;
}

@property (nonatomic, retain)	Category			*categoryForView;
@property (nonatomic, retain)	NSArray			*journalArray;

- (void)fetchJournalForCategory:(Category*)category;

@end
