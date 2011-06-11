//
//  AddMailRecipientController.h
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class AddMailTo;

@interface AddMailRecipientController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
	IBOutlet UITableView			*theTableView;
	
	NSMutableArray					*mailRecipientArray;
	AddMailTo						*mailToController;
}

@property (nonatomic, retain) UITableView		*theTableView;
@property (nonatomic, retain) AddMailTo			*mailToController;
@property (nonatomic, retain) NSMutableArray	*mailRecipientArray;

- (void)saveMailTo;

- (void)selectThisRowAndSave:(NSInteger)row;

@end
