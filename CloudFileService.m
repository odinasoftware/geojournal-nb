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

@implementation CloudFileService

@synthesize documentDirectory;
@synthesize coreDataCloudContent;
//@synthesize coordinator;

- (id)init
{
    if (self = [super init]) {
        self.documentDirectory = [[GeoDefaults sharedGeoDefaultsInstance] geoDocumentPath];
        NSURL *cloudURL = [[GeoDefaults sharedGeoDefaultsInstance] getCloudContainer];        
        self.coreDataCloudContent = [[cloudURL path] stringByAppendingPathComponent:GEO_FOLDER_NAME];
    
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

- (BOOL)isFilesInCloud
{
    NSString *indicator = [self.coreDataCloudContent stringByAppendingPathComponent:GEO_CLOUD_IDC];
    return [_fm fileExistsAtPath:indicator isDirectory:NO];
}
/*
 copyToCloudSandbox:
    Copy all file in the geojournal folder to the cloud sandbox.
    it will eventually sync with the iCloud. 
 */
- (void)copyToCloudSandbox
{
    NSError *error = nil;
    NSString *docsDir = self.documentDirectory;
    NSDirectoryEnumerator *dirEnum = [_fm enumeratorAtPath:docsDir];
    
    TRACE_HERE;
    // Upgrade DB entries to copy to iCloud
    [[GeoDatabase sharedGeoDatabaseInstance] upgradeDBForCloudReady];
    
    // Copy the files to the cloud location
    NSString *file;
    while (file = [dirEnum nextObject]) {
        
        NSString *localFile = [self.documentDirectory stringByAppendingPathComponent:file];
        NSString *cloudFile = [self.coreDataCloudContent stringByAppendingFormat:@"%@/%@", [GeoDefaults sharedGeoDefaultsInstance].UUID, file];
        TRACE("%s: %s\n", [localFile UTF8String], [cloudFile UTF8String]);
        if ([_fm copyItemAtURL:[NSURL fileURLWithPath:localFile] toURL:[NSURL fileURLWithPath:cloudFile] error:&error] == NO) {
            NSLog(@"fail to copy: %@", error);
        }
    }

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
