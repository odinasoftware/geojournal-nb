//
//  CloudService.h
//  GeoJournal
//
//  Created by Jae Han on 2/15/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {CLOUE_NONE, CLOUE_CHECKING, CLOUD_DOWNLOADING, CLOUD_UPLOADING} CLOUD_STATUS;

@interface CloudImageObject : NSObject {
    UIImageView         *image;
    NSString            *url;
    NSMetadataQuery     *query;
}

@property (nonatomic, retain)   UIImageView     *image;
@property (nonatomic, retain)   NSString        *url;
@property (nonatomic, retain)   NSMetadataQuery *query;
@end



@interface CloudService : NSThread {
    @protected
    NSCondition             *itemReady;
    NSMutableArray          *urlList;
    NSMutableDictionary     *contextDict;
    NSMutableDictionary     *urlDict;
    NSMetadataQuery         *metadataSearch;
}

+ (CloudService*)sharedCloudServiceInstance;

- (void)initalGatherComplete:sender;

@end
