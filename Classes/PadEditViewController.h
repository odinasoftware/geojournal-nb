//
//  PadEditViewController.h
//  GeoJournal
//
//  Created by Jae Han on 9/11/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditTextCommon.h"

@interface PadEditViewController : EditTextCommon {
    
}



- (void)doneAction:(id)sender;
- (void)cancelAction:(id)sender;
- (void)registerForKeyboardNotifications;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWasHidden:(NSNotification*)aNotification;

@end
