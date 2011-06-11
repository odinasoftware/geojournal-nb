//
//  GeoSession.h
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect/FBConnect.h"

#define FB_GET_USERNAME			@"facebook.fql.query"
#define FB_UPLOAD_PICTURE		@
@interface GeoSession : NSObject {
	FBSession	*fbSession;
	FBUID		fbUID;
	NSString	*fbUserName;
}

@property (nonatomic, retain) FBSession	*fbSession;
@property (nonatomic) FBUID				fbUID;
@property (nonatomic, retain) NSString *fbUserName;

+ (GeoSession*)sharedGeoSessionInstance;
+ (FBSession*)getFBSession:(id)delegate;

- (void)getUserName;
@end
