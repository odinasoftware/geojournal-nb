//
//  ConnectViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"

@class KeychainItemWrapper;

@interface ConnectViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
	IBOutlet UITableView	*_tableView;
	UISwitch				*switchCtrl;
	NSArray                 *connectObjectArray;
    NSInteger               _passCode;
    NSInteger               _retryPassCode;
    KeychainItemWrapper     *passwordItem;
}

@property (nonatomic, retain) NSArray               *connectObjectArray;
@property (nonatomic, retain) UITableView           *_tableView;
@property (nonatomic, retain) UISwitch              *switchCtrl;
@property (nonatomic, retain) KeychainItemWrapper   *passwordItem;

- (void)switchAction:(id)sender;

@end
