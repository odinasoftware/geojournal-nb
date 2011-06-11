//
//  FacebookConnect.h
//  GeoJournal
//
//  Created by Jae Han on 9/5/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect/FBConnect.h"

typedef enum {FB_REQUEST_NONE=0, FB_REQUEST_LOGIN=1, FB_REQUEST_USERNAME=2, FB_REQUEST_PERMISSION=3, FB_UPLOAD_PICTURE=4, FB_UPLOAD_STORY=5} FBRequestType;

@class Journal;

@interface FacebookConnect : NSObject <FBDialogDelegate, FBRequestDelegate, FBSessionDelegate> {
	Journal				*journalToPost;
	UIImage				*imageForJournal;
	
	@private
	FBRequestType		_fbCallType;
	UIAlertView			*_alertView;
	BOOL				_notifySuccess;
}

@property (nonatomic, retain) UIImage			*imageForJournal;
@property (nonatomic, retain) Journal			*journalToPost;
@property (nonatomic, retain) UIAlertView		*_alertView;

- (void)publishToFacebook:(NSString*)image_url;
- (void)publishToFacebookForJournal:(Journal*)j withImage:(UIImage*)image;

- (void)publishPhotoToFacebook;
- (void)loginToFacebookWithNotification:(BOOL)notify;
- (void)showFacebookConnectError:(NSString*)description;

@end
