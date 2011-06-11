//
//  JournalViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/10/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Category;
@class GeoTakeController;
@class JournalEntryViewController;

@interface DateIndex : NSObject
{
	NSString	*dateString;
	NSInteger	index;
}

@property (nonatomic, retain) NSString		*dateString;
@property (nonatomic) NSInteger				index;

@end

@interface JournalViewController : UITableViewController {
	Category						*categoryForView;
	NSArray							*journalArray;
	UIImage							*defaultImage;
	BOOL							needToReload;
	BOOL							isCategoryChanged;
	
	@private
	NSMutableArray					*_dateArray;
	JournalEntryViewController		*_journalView;
	GeoTakeController				*journalController;
}

@property (nonatomic, retain)	UIImage						*defaultImage;
@property (nonatomic, retain)	Category					*categoryForView;
@property (nonatomic, retain)	NSArray						*journalArray;
@property (nonatomic, retain)	NSMutableArray				*_dateArray;
@property (nonatomic, retain)	GeoTakeController			*journalController;
@property (nonatomic, retain)	JournalEntryViewController	*_journalView;

@property (nonatomic)			BOOL			isCategoryChanged;

- (void)restoreLevel;
- (void)reloadJournalArray;
- (void)saveJournalToDatabase;
- (void)setReload:(BOOL)reload;
- (void)fetchJournalForCategory:(Category*)category;

@end
