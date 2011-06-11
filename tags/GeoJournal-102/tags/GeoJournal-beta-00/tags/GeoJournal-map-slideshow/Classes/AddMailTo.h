//
//  AddCategory.h
//  GeoJournal
//
//  Created by Jae Han on 7/8/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AddMailTo : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
	//IBOutlet	UITextField		*textField;
	IBOutlet	UITableView		*theTableView;
	
	UITextField				*textInputField;
	BOOL						saveResult;
}

//@property (nonatomic, retain) UITextField	*textField;
@property (nonatomic, retain) UITableView		*theTableView;
@property (nonatomic, retain, readonly) UITextField	*textInputField;
@property (nonatomic) BOOL saveResult;

- (void)doneAction;
- (void)cancelAction;

@end
