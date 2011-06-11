//
//  TextInputController.h
//  GeoJournal
//
//  Created by Jae Han on 7/9/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TextInputController : NSObject <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate> {
	IBOutlet	UITableView		*theTableView;
	
	UITextField					*titleView;
	UITextView					*contentView;

	UITextView					*activeView;
	BOOL						keyboardShown;
}

@property (nonatomic, retain)			UITableView		*theTableView;
@property (nonatomic, retain, readonly) UITextField		*titleView;
@property (nonatomic, retain, readonly) UITextView		*contentView;

- (void)registerForKeyboardNotifications;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWasHidden:(NSNotification*)aNotification;


@end
