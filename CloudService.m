//
//  CloudService.m
//  GeoJournal
//
//  Created by Jae Han on 2/15/12.
//  Copyright (c) 2012 Home. All rights reserved.
//
#import "GeoJournalHeaders.h"
#import "CloudService.h"
#import "CloudFileService.h"

static CloudService *sharedCloudService = nil;

@implementation CloudImageObject

@synthesize image, url, query;

@end

@implementation CloudService

+ (CloudService*)sharedCloudServiceInstance
{
    if (sharedCloudService == nil) {
        [[self alloc] init];
    }
    
    return sharedCloudService;
}

+ (id)allocWithZone:(NSZone *)zone
{
    if (sharedCloudService == nil) {
        sharedCloudService = [super allocWithZone:zone];
        return sharedCloudService;
    }
    return nil;
}

- (void)addURL:(NSString*)url withGraphicContext:(UIImageView*)view
{
    // Add url with the uiimageview in the dictionary.
    // There'll be two dictionaries: url -> context, context -> url.
}

- (void)checkCloud:(NSString*)url
{
    
}

- (void)sendIt:(NSString*)file toCloud:(CloudFileService*)service
{
    NSError *error = nil;
    NSString *cloudFile = [service.coreDataCloudContent stringByAppendingPathComponent:file];
    NSString *localFile = [service.documentDirectory stringByAppendingPathComponent:file];
    
    TRACE("%s, [local : %s], [cloud: %s]\n", __func__, [localFile UTF8String], [cloudFile UTF8String]);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager setUbiquitous:YES 
                     itemAtURL:[NSURL fileURLWithPath:localFile]
                destinationURL:[NSURL fileURLWithPath:cloudFile] error:&error];
    
    if (error) {
        NSLog(@"%s, %@", __func__, error);
    }
}

// Method invoked when notifications of content batches have been received
- (void)queryDidUpdate:sender;
{
    NSLog(@"A data batch has been received");
}


// Method invoked when the initial query gathering is completed
- (void)initalGatherComplete:sender;
{
    NSMetadataQuery *query = [sender object];
    
    TRACE("%s, %d\n", __func__, [query resultCount]);
    
    // Stop the query, the single pass is completed.
    [query stopQuery];
    
    if ([query resultCount] == 0) {
        // No file exists. If local exists, then upload it.
        // Otherwise, there is no image. 
        
    }
    // Process the content. In this case the application simply
    // iterates over the content, printing the display name key for
    // each image
    NSInteger i=0;
    for (i=0; i < [query resultCount]; i++) {
        NSMetadataItem *theResult = [query resultAtIndex:i];
        NSString *displayName = [theResult valueForAttribute:(NSString *)NSMetadataItemDisplayNameKey];
        TRACE("result at %d - %s\n", i, [displayName UTF8String]);
    }
    
    // Remove the notifications to clean up after ourselves.
    // Also release the metadataQuery.
    // When the Query is removed the query results are also lost.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidUpdateNotification
                                                  object:query];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidFinishGatheringNotification
                                                  object:query];
    [query release];
}


- (void)searchInCloud:(NSString*)url
{
    TRACE("%s, url: %s\n", __func__, [url UTF8String]);
    NSMetadataQuery *metadataSearch = [[NSMetadataQuery alloc] init];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K like %@", NSMetadataItemFSNameKey, url];
    [metadataSearch setPredicate:predicate];
    
    // Register the notifications for batch and completion updates
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryDidUpdate:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:metadataSearch];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initalGatherComplete:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:metadataSearch];
    
    // Set the search scope. In this case it will search the User's home directory
    // and the iCloud documents area
    NSArray *searchScopes;
    searchScopes=[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope,nil];
    [metadataSearch setSearchScopes:searchScopes];
    
    // Configure the sorting of the results so it will order the results by the
    // display name
    /*
     NSSortDescriptor *sortKeys=[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemDisplayName
     ascending:YES] autorelease];
     [metadataSearch setSortDescriptors:[NSArray arrayWithObject:sortKeys]];
     */
    TRACE("metadata search: %d, gathering: %d, stopped: %d, count: %d\n", [metadataSearch isStarted], [metadataSearch isGathering], [metadataSearch isStopped], [metadataSearch resultCount]);
    if ([metadataSearch startQuery] == NO) {
        TRACE("%s, query failed.\n", __func__);
    }
    
}

/*
 Multithread handling of cloud
 checking, uploading, and downloading.
 */
- (void)main
{
    NSString    *url = nil;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    TRACE_HERE;
    CloudFileService *cloudFileService = [[CloudFileService alloc] init];
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:cloudFileService];
    NSError *error = nil;
        
    /*
     [coordinator coordinateReadingItemAtURL:[cloudFileService presentedItemURL]  options:0 error:&error byAccessor:^ (NSURL *newURL) {
     TRACE("%s, new url: %s\n", __func__, [[newURL absoluteString] UTF8String]);
     }];
     
     if (error) {
     NSLog(@"%s, %@", __func__, error);
     }
     */
    
    [self searchInCloud:@"*"];
    for (;;) {
        /*
        NSString *docsDir = cloudFileService.documentDirectory;
        NSFileManager *localFileManager=[[NSFileManager alloc] init];
        NSDirectoryEnumerator *dirEnum = [localFileManager enumeratorAtPath:docsDir];
        
        NSString *file;
        while (file = [dirEnum nextObject]) {
        
            [self sendIt:file toCloud:cloudFileService];
            

        }
        [localFileManager release];
        */
    
        //("metadata search: %d, gathering: %d, stopped: %d, count: %d\n", [metadataSearch isStarted], [metadataSearch isGathering], [metadataSearch isStopped], [metadataSearch resultCount]);
        sleep(3);
    }
    
    TRACE("%s, end\n", __func__);
    [pool release];
}

@end
