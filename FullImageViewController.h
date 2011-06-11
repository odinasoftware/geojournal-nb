//
//  FullImageViewController.h
//  GeoJournal
//
//  Created by Jae Han on 10/2/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideImageView.h"
#import "TapDetectingImageView.h"

@class JournalEntryViewController;

@interface FullImageViewController : UIViewController <UIScrollViewDelegate, TapDetectingImageViewDelegate, UIAlertViewDelegate> {
	IBOutlet TapDetectingImageView		*imageView;
	IBOutlet UIScrollView				*imageScrollView;
	
	JournalEntryViewController			*parent;
	
	@private
	PRESS_STATUS						_press_status;
	NSTimeInterval						_timestamp;
	NSInteger							_swipe_loc;
	NSMutableArray						*pictures;
	UIBarButtonItem						*trashButton;
	
	int           firstVisiblePageIndexBeforeRotation;
    CGFloat       percentScrolledIntoFirstVisiblePage;
}

@property (nonatomic, retain) TapDetectingImageView			*imageView;
@property (nonatomic, retain) UIScrollView					*imageScrollView;
@property (nonatomic, retain) JournalEntryViewController	*parent;
@property (nonatomic, retain) NSMutableArray				*pictures;
@property (nonatomic, retain) UIBarButtonItem				*trashButton;

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;
- (void)removeThisPicture:(id)sender;
- (void)removeCurrentPicture;
- (void)redraw;

@end
