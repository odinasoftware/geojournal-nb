//
//  GeoSplitTableController.h
//  GeoJournal
//
//  Created by Jae Han on 10/18/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SubstitutableDetailViewController
- (void)showRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem;
- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem;
@end

@interface GeoSplitTableController : UITableViewController <UISplitViewControllerDelegate> {
    UISplitViewController           *splitViewController;
    
    UIPopoverController             *popoverController;    
    UIBarButtonItem                 *rootPopoverButtonItem;
    
    NSMutableArray					*categoryArray;
    NSArray							*defaultCategory;

}

@property (nonatomic, assign) IBOutlet  UISplitViewController   *splitViewController;

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) UIBarButtonItem *rootPopoverButtonItem;

@property (nonatomic, retain)	NSMutableArray				*categoryArray;
@property (nonatomic, retain)	NSArray						*defaultCategory;

- (void)loadFromDatabase;

@end
