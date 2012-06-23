//
//  StatusViewController.h
//  JeJuSite
//
//  Created by Jae Han on 7/5/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {DEFAULT_PROGRESS_TYPE, CLOUD_READY_PROGRESS_TYPE} status_view_type_t;

@interface ProgressViewController : UIViewController <UIAlertViewDelegate> {
	IBOutlet	UIView						*innerRectangle;
	IBOutlet	UILabel						*statusLabel;
	IBOutlet	UIButton					*cancelButton;
	IBOutlet	UIActivityIndicatorView		*activityView;
    
    status_view_type_t                      view_type;
}

@property (nonatomic, retain) UIView	*innerRectangle;
@property (nonatomic, retain) UILabel	*statusLabel;
@property (nonatomic, retain) UIButton	*cancelButton;
@property (nonatomic, assign) status_view_type_t view_type;
@property (nonatomic, retain) UIActivityIndicatorView	*activityView;

- (id)initWithType:(status_view_type_t)view_type;
- (IBAction)cancelDownloading:(id)sender;
- (void)cancelSearching;

@end

@interface ProgressViewControllerHolder : NSObject
{
	ProgressViewController		*_statusView;
	
	@private
	status_view_type_t			_statusType;
}

@property (nonatomic, retain) ProgressViewController *statusView;

+ (ProgressViewControllerHolder*)sharedStatusViewControllerInstance;

- (void)showStatusView:(UIView*)controller type:(status_view_type_t)view_type;
- (void)removeFromSuperview:(status_view_type_t)type;

@end
