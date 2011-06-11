//
//  ButtonScrollView.h
//  GeoJournal
//
//  Created by Jae Han on 7/13/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {BUTTON_NONE, BUTTON_PRESSED, BUTTON_MOVED, BUTTON_UP} button_touch_type_t;

@class NoteViewController;

@interface ButtonScrollView : UIScrollView <UIScrollViewDelegate> {
	NoteViewController		*noteDelegate;
	button_touch_type_t		touchEvent;
}

@property (nonatomic, retain) NoteViewController *noteDelegate;

@end
