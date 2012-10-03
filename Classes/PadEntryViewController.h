//
//  PadEntryViewController.h
//  GeoJournal
//
//  Created by Jae Han on 11/14/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <Twitter/TWTweetComposeViewController.h>

#import "ImageFrameView.h"
#import "FacebookConnect.h"
#import "JournalEntryViewCommon.h"

@class Journal;
@class PadEditViewController;
@class JournalViewController;

@interface PadEntryViewController : JournalEntryViewCommon {

    @protected
    //PadEditViewController			*editTextController;
    
    @private
    UIInterfaceOrientation  _toOrientation;
}

- (IBAction)popUpPrevView:(id)sender;

//@property (nonatomic, retain) PadEditViewController			*editTextController;

@end
