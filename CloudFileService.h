//
//  CloudFileService.h
//  GeoJournal
//
//  Created by Jae Han on 2/25/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudFileService : NSObject <NSFilePresenter> {
    @private
    NSString            *documentDirectory;

    //NSFileCoordinator   *coordinator;
    
    NSURL               *_presentedItemURL;
    NSOperationQueue    *_presentedItemOperationQueue;
    NSFileManager       *_fm;
}

@property (readonly)            NSURL               *presentedItemURL;
@property (readonly)            NSOperationQueue    *presentedItemOperationQueue;

@property (nonatomic, retain)   NSString            *documentDirectory;

//@property (nonatomic, retain)   NSFileCoordinator   *coordinator;

@end
