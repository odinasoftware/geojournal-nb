//
//  EditText.h
//  GeoJournal
//
//  Created by Jae Han on 10/22/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EditText : UIViewController {
	IBOutlet	UITextView		*textView;
	NSString					*text;
	
	@private
	BOOL						keyboardShown;
}

@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) NSString *text;

- (void)doneAction:(id)sender;
- (void)cancelAction:(id)sender;
- (void)registerForKeyboardNotifications;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWasHidden:(NSNotification*)aNotification;

@end
