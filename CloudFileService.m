//
//  CloudFileService.m
//  GeoJournal
//
//  Created by Jae Han on 2/25/12.
//  Copyright (c) 2012 Home. All rights reserved.
//
#import "GeoJournalHeaders.h"
#import "GeoDefaults.h"
#import "CloudFileService.h"
#import "GeoDatabase.h"
#import "CloudService.h"

@implementation CloudFileService

@synthesize documentDirectory;

//@synthesize coordinator;

- (id)init
{
    if (self = [super init]) {
        self.documentDirectory = [[GeoDefaults sharedGeoDefaultsInstance] geoDocumentPath];
    
        _fm = [NSFileManager defaultManager];
        // TODO: if coreDataCloudContent is null, then cloud is disable.
        /*
        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager setUbiquitous:YES 
                         itemAtURL:_presentedItemURL
                    destinationURL:[NSURL fileURLWithPath:self.coreDataCloudContent] error:&error];
        */
        TRACE("%s, doc: %s\n", __func__, [self.documentDirectory UTF8String]);
    }
    
    return self;
}

/*
 Things to do:
 1. How to associate local and cloud location.
 */
- (NSURL*) presentedItemURL
{
    if (_presentedItemURL == nil) {
        _presentedItemURL = [NSURL fileURLWithPath:self.documentDirectory];
    }
    
    return _presentedItemURL;
}

- (NSOperationQueue*) presentedItemOperationQueue 
{
    if (_presentedItemOperationQueue == nil) {
        _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
    }
    
    return _presentedItemOperationQueue;
}

// Notifies your object that another object or process wants to read the presented file or directory.
// when this method is called, you might temporarily stop making changes to the file or directory. 
// After taking any appropriate steps, you must execute the block in the reader parameter to let the waiting object know that it may now proceed with its task. 
// If you want to be notified when the reader has completed its task, pass your own block to the reader and use that block to reacquire the file or URL for your own uses.

- (void)relinquishPresentedItemToReader:(void (^)(void (^reacquirer)(void)))reader
{
    TRACE_HERE;
}

// Notifies your object that another object or process wants to write to the presented file or directory.
// when this method is called, you would likely stop making changes to the file or directory. 
// After taking any appropriate steps, you must execute the block in the writer parameter to let the waiting object know that it may now proceed with its task. 
// If you want to be notified when the writer has completed its task, pass your own block to the writer and use that block to reacquire the file or URL for your own uses.

- (void)relinquishPresentedItemToWriter:(void (^)(void (^reacquirer)(void)))writer
{
    TRACE_HERE;
}

// completionHandler: The Block object to call after you save your changes.
- (void)savePresentedItemChangesWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler
{
    TRACE_HERE;
}

// Tells the delegate that some entity wants to delete an item that is inside of a presented directory. (required)
- (void)accommodatePresentedSubitemDeletionAtURL:(NSURL *)url completionHandler:(void (^)(NSError *errorOrNil))completionHandler
{
    TRACE_HERE;
}

// Tells the delegate that an item was added to the presented directory. (required)
- (void)presentedSubitemDidAppearAtURL:(NSURL *)url
{
    TRACE_HERE;
}

// Tells the delegate that an item in the presented directory moved to a new location. (required)
- (void)presentedSubitemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL
{
    TRACE_HERE;
}

// Tells the delegate that the contents or attributes of the specified item changed. (required)
- (void)presentedSubitemDidChangeAtURL:(NSURL *)url
{
    TRACE_HERE;
}

- (void)dealloc
{
    [_presentedItemURL release];
    [_presentedItemOperationQueue release];
}
@end
