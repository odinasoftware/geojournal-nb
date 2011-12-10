//
//  GeoSplitViewController.h
//  GeoJournal
//
//  Created by Jae Han on 10/15/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GeoSplitViewController : UISplitViewController {
    IBOutlet UITableViewController       *tableView;
}

@property   (nonatomic, retain) UITableViewController   *tableView;

@end
    