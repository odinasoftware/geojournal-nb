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
#import "GeoDefaults.h"
#import "GeoDatabase.h"

static CloudService *sharedCloudService = nil;

@implementation CloudImageObject

@synthesize image, url, query;

@end

@implementation CloudService

@synthesize cloudContainer;
@synthesize metadataSearch;

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

- (id)init
{
    if ((self = [super init])) {
        _fm = [NSFileManager defaultManager];
    }
    
    return self;
}

- (void)addURL:(NSString*)url withGraphicContext:(UIImageView*)view
{
    // Add url with the uiimageview in the dictionary.
    // There'll be two dictionaries: url -> context, context -> url.
}

- (void)checkCloud:(NSString*)url
{
    
}

/*
- (void)sendIt:(NSString*)file toCloud:(CloudFileService*)service
{
    NSError *error = nil;
    NSString *cloudFile = [service.coreDataCloudContent stringByAppendingPathComponent:file];
    NSString *localFile = [service.documentDirectory stringByAppendingPathComponent:file];
    
    TRACE("%s, [local : %s], [cloud: %s]\n", __func__, [localFile UTF8String], [cloudFile UTF8String]);
    
    [_fm setUbiquitous:YES 
             itemAtURL:[NSURL fileURLWithPath:localFile]
        destinationURL:[NSURL fileURLWithPath:cloudFile] error:&error];
    
    if (error) {
        NSLog(@"%s, %@", __func__, error);
    }
}
 */

// Method invoked when notifications of content batches have been received
- (void)queryDidUpdate:sender;
{
    NSLog(@"A data batch has been received");
}


// Method invoked when the initial query gathering is completed
- (void)initalGatherComplete:sender;
{
    //NSMetadataQuery *query = [sender object];
    
    TRACE("%s, %d\n", __func__, [self.metadataSearch resultCount]);
    
    // Stop the query, the single pass is completed.
    [self.metadataSearch stopQuery];
    
    if ([self.metadataSearch resultCount] == 0) {
        // No file exists. If local exists, then upload it.
        // Otherwise, there is no image. 
        
    }
    // Process the content. In this case the application simply
    // iterates over the content, printing the display name key for
    // each image
    NSInteger i=0;
    for (i=0; i < [self.metadataSearch resultCount]; i++) {
        NSMetadataItem *theResult = [self.metadataSearch resultAtIndex:i];
        NSString *displayName = [theResult valueForAttribute:(NSString *)NSMetadataItemDisplayNameKey];
        TRACE("result at %d - %s\n", i, [displayName UTF8String]);
    }
    
    // Remove the notifications to clean up after ourselves.
    // Also release the metadataQuery.
    // When the Query is removed the query results are also lost.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidUpdateNotification
                                                  object:self.metadataSearch];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidFinishGatheringNotification
                                                  object:self.metadataSearch];
    self.metadataSearch = nil;
}


#pragma Cloud Management
- (NSURL*)getCloudContainer
{
    if (cloudContainer == nil) {
                
        // this needs to match the entitlements and provisioning profile
        self.cloudContainer = [_fm URLForUbiquityContainerIdentifier:nil];
    }
    return self.cloudContainer;
}

- (NSString*)getCloudGeoJournalContainer
{
    NSString* cloudContent = [[[self getCloudContainer] path] stringByAppendingPathComponent:@"GeoJournal"];
    
    return cloudContent;
}

- (NSString*)getCloudURL:(NSString*)lastComponent willCreate:(BOOL)create
{
    NSString *url;
    NSError *error = nil;
    
    url = [[self getCloudGeoJournalContainer] stringByAppendingPathComponent:lastComponent];
    
    if (url != nil && create == YES) {
        
        if ([_fm fileExistsAtPath:url] == NO && 
            [_fm createDirectoryAtURL:[NSURL fileURLWithPath:url] withIntermediateDirectories:YES attributes:nil error:&error] == NO) {
            if (error) {
                NSLog(@"%s, file does not exist in cloud: %@", __func__, url);
            }
        }

        /*
        error = nil;
        // see if it exists in the cloud, otherwise we will need to create it.
        [_fm setUbiquitous:YES 
                 itemAtURL:[NSURL fileURLWithPath:url]
            destinationURL:[self getCloudContainer] error:&error];
        
        if (error) {
            NSLog(@"%s, %@", __func__, error);
        }
         */

    }
    
    
    return url;
}

- (void)listFilesInCloud:(NSString*)folder
{
    dispatch_async(dispatch_get_current_queue(), ^{
           
        NSError *error = nil;
        
        NSString *temp = [[CloudService sharedCloudServiceInstance] getCloudURL:folder willCreate:YES];
        //NSURL *u = [NSURL fileURLWithPath:service.coreDataCloudContent isDirectory:YES];
        NSURL *u = [NSURL fileURLWithPath:temp isDirectory:YES];
        NSLog(@"url: %@", u);
        NSArray *files = [_fm contentsOfDirectoryAtURL:u
                            includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsRegularFileKey, nil] 
                                               options:NSDirectoryEnumerationSkipsHiddenFiles 
                                                 error:&error];
        
        if (error) {
            NSLog(@"%s: %@", __func__, error);
            return;
        }
        TRACE("%s, file count: %d\n", __func__, [files count]);
        
        NSNumber *aBool = nil;
        NSNumber *isDownloaded = nil;
        NSString *fileName = nil;
        for (NSURL *f in files) {
            [f getResourceValue:&aBool forKey:NSURLIsDirectoryKey error:&error];
            if (aBool && ![aBool boolValue]) {
                [f getResourceValue:&isDownloaded forKey:NSURLUbiquitousItemIsDownloadedKey error:&error];
                [f getResourceValue:&fileName forKey:NSURLNameKey error:&error];
                NSLog(@"file: %@, downloaded: %d, %@", f, [isDownloaded boolValue], fileName);
                
                if (isDownloaded != nil) {
                    if (![isDownloaded boolValue]) {
                        if ([[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:f error:&error] == NO) {
                            NSLog(@"faile to download: %@", error);
                        }
                        
                    }/*
                      else {
                      NSString *localFile = [service.documentDirectory stringByAppendingPathComponent:fileName];
                      TRACE("%s\n", [localFile UTF8String]);
                      if ([fm copyItemAtURL:f toURL:[NSURL fileURLWithPath:localFile] error:&error] == NO) {
                      NSLog(@"fail to copy: %@", error);
                      }
                      }*/
                }
            }
        }
        
    });
    
}

- (BOOL)isFilesInCloud
{
    // TODO: we will have to search cloud to this indication. 
    // think abot asynchronous return.
    return NO; //[self searchInCloud:GEO_CLOUD_IDC];
    
    //NSString *indicator = [[self.cloudContainer path] URLByAppendingPathComponent:GEO_CLOUD_IDC];
    //return [_fm fileExistsAtPath:indicator isDirectory:NO];
}

- (void)setBaseSyncFlagInCloud
{
    // TODO: how to write a file in cloud. 
}

- (void)putIndicator:(NSString*)cloudDir
{
    NSError *error = nil;
    NSString *localIndicator = [[[GeoDefaults sharedGeoDefaultsInstance] geoDocumentPath] stringByAppendingPathComponent:GEO_CLOUD_IDC];
    NSString *cloudIndicator = [cloudDir stringByAppendingPathComponent:GEO_CLOUD_IDC];
    
    NSString *content = [NSString stringWithString:GEO_CLOUD_IDC];
    NSData *dataContent = [NSData dataWithBytes:(void*)[content UTF8String] length:[content length]];
    if ([_fm createFileAtPath:localIndicator
                     contents:dataContent 
                   attributes:nil] == NO) {
        NSLog(@"%s, can't create the cloud indicator.", __func__);
        return;
    }
    
    if ([_fm setUbiquitous:YES 
                 itemAtURL:[NSURL fileURLWithPath:localIndicator] 
            destinationURL:[NSURL fileURLWithPath:cloudIndicator] error:&error] != YES) {
        NSLog(@"%s: fail to upload sync indicator: %@", __func__, error);
    }
    
}

- (void)uploadBaselineFiles
{

    NSError *error = nil;
    NSString *docsDir = [[GeoDefaults sharedGeoDefaultsInstance] geoDocumentPath];
    
    NSString *cloudGeoJournalDir = [[CloudService sharedCloudServiceInstance] getCloudURL:[GeoDefaults sharedGeoDefaultsInstance].UUID willCreate:YES];
    TRACE("%s: cloud: %s\n", __func__, [cloudGeoJournalDir UTF8String]);
#if 0    
    // Copy the files to the cloud location
    NSDirectoryEnumerator *dirEnum = [_fm enumeratorAtPath:docsDir];
    
    //TRACE("%s, count: %d\n", __func__, [[dirEnum allObjects] count]);
    NSString *file;
    while (file = [dirEnum nextObject]) {
        
        NSURL *localFile = [NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:file]];
        NSURL *cloudFile = [NSURL fileURLWithPath:[cloudGeoJournalDir stringByAppendingPathComponent:file]];
        TRACE("%s: %s\n", [[localFile absoluteString] UTF8String], [[cloudFile absoluteString] UTF8String]);
#ifdef MOVE_TO_CLOUD
        [_fm setUbiquitous:YES
                 itemAtURL:[NSURL fileURLWithPath:localFile]
            destinationURL:[NSURL fileURLWithPath:cloudFile] error:&error];
#endif
        if ([_fm copyItemAtURL:localFile toURL:cloudFile error:&error] != YES) {
            NSLog(@"Fail to copy to the cloud location: %@", error);
        }
        
    }
#endif
    // Everything is done, put the indicator.
    [self putIndicator:cloudGeoJournalDir];
}

- (void)checkBaselineSync:(id)sender
{
    // TODO: see if we have the synced file.
    // if it does not exist in there, then start baseline sync.
        
    TRACE("%s, %d\n", __func__, [self.metadataSearch resultCount]);
    
    // Stop the self.metadataSearch, the single pass is completed.
    [self.metadataSearch stopQuery];
    
    if ([self.metadataSearch resultCount] == 0) {
        // Start the baseline sync now.
        [self uploadBaselineFiles];
    }
    else {
        // TODO: We have the baseline synced. Now we need to determine which directories need to be donwloaded.
        
        // Process the content. In this case the application simply
        // iterates over the content, printing the display name key for
        // each image
        NSInteger i=0;
        for (i=0; i < [self.metadataSearch resultCount]; i++) {
            NSMetadataItem *theResult = [self.metadataSearch resultAtIndex:i];
            NSString *displayName = [theResult valueForAttribute:(NSString *)NSMetadataItemDisplayNameKey];
            TRACE("result at %d - %s\n", i, [displayName UTF8String]);
        }
    }
    
    // Remove the notifications to clean up after ourselves.
    // Also release the metadataQuery.
    // When the Query is removed the query results are also lost.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidUpdateNotification
                                                  object:self.metadataSearch];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidFinishGatheringNotification
                                                  object:self.metadataSearch];
    self.metadataSearch = nil;
    
}

- (void)searchInCloud:(NSString*)url delegate:(SEL)delegate
{
    TRACE("%s, url: %s\n", __func__, [url UTF8String]);
    NSMetadataQuery *meta = [[NSMetadataQuery alloc] init];
    self.metadataSearch = meta;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K like %@", NSMetadataItemFSNameKey, url];
    [self.metadataSearch setPredicate:predicate];
    
    // Register the notifications for batch and completion updates
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryDidUpdate:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:metadataSearch];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:delegate
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:metadataSearch];
    
    // Set the search scope. In this case it will search the User's home directory
    // and the iCloud documents area
    NSArray *searchScopes;
    searchScopes=[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDataScope, nil];
    [metadataSearch setSearchScopes:searchScopes];
    
    // Configure the sorting of the results so it will order the results by the
    // display name
    /*
     NSSortDescriptor *sortKeys=[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemDisplayName
     ascending:YES] autorelease];
     [metadataSearch setSortDescriptors:[NSArray arrayWithObject:sortKeys]];
     */
    //TRACE("metadata search: %d, gathering: %d, stopped: %d, count: %d\n", [metadataSearch isStarted], [metadataSearch isGathering], [metadataSearch isStopped], [metadataSearch resultCount]);
    if ([self.metadataSearch startQuery] == NO) {
        TRACE("%s, query failed.\n", __func__);
    }
    [meta release];
}

/*
 copyToCloudSandbox:
 Copy all file in the geojournal folder to the cloud sandbox.
 it will eventually sync with the iCloud. 
 */
- (void)copyToCloudSandbox
{
    
    // Upgrade DB entries to copy to iCloud
    [[GeoDatabase sharedGeoDatabaseInstance] upgradeDBForCloudReady];
    
    // TODO: see if the baseline is synced
    [self searchInCloud:GEO_CLOUD_IDC delegate:@selector(checkBaselineSync:)];
    
}

#pragma -

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

- (void)dealloc
{
    [cloudContainer release];
    [metadataSearch release];
}

@end
