//
//  StatusViewController.h
//  JeJuSite
//
//  Created by Jae Han on 7/5/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageArrayScrollController;
@class Journal;
@class SlideImageView;
@protocol SelectImageDelegate;

@interface StatusViewController : UIViewController <UIAlertViewDelegate> {
	IBOutlet	UIView						*innerRectangle;
	IBOutlet	UILabel						*statusLabel;
	IBOutlet	UIButton					*cancelButton;
	IBOutlet	UIButton					*okButton;
	//IBOutlet	SlideImageView				*slideImageView;
	IBOutlet	ImageArrayScrollController	*imageArrayView;
	
	
}

@property (nonatomic, retain) UIView	*innerRectangle;
@property (nonatomic, retain) UILabel	*statusLabel;
@property (nonatomic, retain) UIButton	*cancelButton;
@property (nonatomic, retain) UIButton	*okButton;
//@property (nonatomic, retain) SlideImageView *slideImageView;
@property (nonatomic, retain) ImageArrayScrollController *imageArrayView;

- (IBAction)cancelDownloading:(id)sender;
- (IBAction)okSelection:(id)sender;
- (void)cancelSearching;

@end

@interface StatusViewControllerHolder : NSObject
{
	StatusViewController					*_statusView;
	id <SelectImageDelegate>				delegate;
}

@property (nonatomic, retain) StatusViewController *statusView;
@property (nonatomic, assign) id<SelectImageDelegate>	delegate;

+ (StatusViewControllerHolder*)sharedStatusViewControllerInstance;
- (ImageArrayScrollController*)getImageArrayController;
- (void)showStatusView:(UIView*)controller withJournal:(Journal*)entry withImages:(NSMutableArray*)pictures withMessage:(NSString*)message delegate:(id)delegate;
- (void)removeFromSuperview:(BOOL)notify;

@end

@protocol SelectImageDelegate <NSObject>

@optional
- (void)selectImage:(NSString*)picuture;

@end