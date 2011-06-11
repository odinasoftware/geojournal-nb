//
//  ConnectViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect/FBConnect.h"


@interface ConnectViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
	IBOutlet UITableView	*_tableView;
	
	NSArray				*connectObjectArray;
}

@property (nonatomic, retain) NSArray		*connectObjectArray;
@property (nonatomic, retain) UITableView		*_tableView;


@end
