//
//  ConnectViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"


@interface ConnectViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
	IBOutlet UITableView	*_tableView;
	UISwitch				*switchCtrl;
    UISwitch                *cloudCtrl;
	NSArray                 *connectObjectArray;
    NSInteger               _passCode;
    NSInteger               _retryPassCode;
}

@property (nonatomic, retain) NSArray               *connectObjectArray;
@property (nonatomic, retain) UITableView           *_tableView;
@property (nonatomic, retain) UISwitch              *switchCtrl;
@property (nonatomic, retain) UISwitch              *cloudCtrl;

- (void)switchAction:(id)sender;
- (void)cloudAction:(id)sender;

@end
