
//
//  GeoDatabase.m
//  GeoJournal
//
//  Created by Jae Han on 7/8/09.
//  Copyright 2009 Home. All rights reserved.
//

#include <pthread.h>

#import "GeoDatabase.h"
#import "GeoDefaults.h"
#import "MailRecipients.h"
#import "GCategory.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "PictureFrame.h"
#import "Pictures.h"
#import "GeoDefaults.h"
                                            
#define UBIQUITY_CONTAINER_URL @"WV3CVJV89H.com.odinasoftware.igeojournal" 

/*
 * iCloud todos:
 *    1. Create and save the file locally in the sandbox
 *    2. Use UIDocument class to manage the file
 *    3. Create NSURL object that specifies the destination of the file in a user's iCloud storage.
 *        Use "Documents" subdirectory.
 *    4. Call 'setUbiquitous' to move the file to the iCloud. 
 */
extern NSString *getThumbnailFilename(NSString *filename);

static GeoDatabase	*sharedGeoDatabase = nil;

void *remove_file_in_thread(void* arg)
{
	NSError *error = nil;
	pthread_detach(pthread_self());
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *file = (NSString*) arg;
	
	if ([[NSFileManager defaultManager] removeItemAtPath:file error:&error] == FALSE) {
		NSLog(@"%s, fail to remove a file: %@", __func__, error);
	}
	
	NSString *thumb = getThumbnailFilename(file);
	
	if ([[NSFileManager defaultManager] removeItemAtPath:thumb error:&error] == FALSE) {
		NSLog(@"%s, fail to remove a thumb file: %@", __func__, error);
	}
	
	[thumb release];
		
	[pool release];
	return nil;
}

void remove_file(NSString *file) 
{	
	pthread_t thread;
	
	pthread_create(&thread, nil, (void*)(remove_file_in_thread), (void*)file);
}

@implementation GeoCloudDocument

/*
- (NSManagedObjectModel *) managedObjectModel 
{
    // Need to have this, otherwise UIManagedDocument is not properly loaded.
    if (managedObjectModel) {
        return managedObjectModel;
    }
    
    TRACE("%s\n", __func__);
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GeoJournal"ofType:@"momd"];
	NSURL *momURL = [NSURL fileURLWithPath:path];
    
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    
    return managedObjectModel;
}
*/

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    id me;
    
    NSLog(@"%s, %@", __func__, typeName);
    
    NSData *data = [[NSData alloc] initWithBytes:"test" length:4];
    
    me = data;
    return nil;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL res = FALSE;
    
    NSLog(@"%s", __func__);
    // Getting data from the local sandbox, save it to cloud
    
    //NSData *data = contents;
    
    //NSFileManager *fileManager = [NSFileManager defaultManager];
    //NSURL *ubiquityContainerURL = [[fileManager URLForUbiquityContainerIdentifier:UBIQUITY_CONTAINER_URL] URLByAppendingPathComponent:@"Documents"];
    
    /*
    int i=0;
    const char* c = [data bytes];
    for (i=0; i<[data length]; ++i) {
        printf("%c \n", c[i]);
    }
     */
    
    
    return res;
}

@end

@implementation GeoDatabase

@synthesize journalDict;
@synthesize managedDocument;
@synthesize metaQuery;
@synthesize ubiquitousQuery=ubiquitousQuery__;
@synthesize managedObjectContext;

+ (GeoDatabase*)sharedGeoDatabaseInstance
{
	//@synchronized (self) {
	if (sharedGeoDatabase == nil) {
		[[self alloc] init];
	}
	//}
	return sharedGeoDatabase;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedGeoDatabase == nil) { 
			sharedGeoDatabase = [super allocWithZone:zone]; 
			return sharedGeoDatabase;
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

-(id)init 
{
	self = [super init];
	if (self) {
		journalDict = [[NSMutableDictionary alloc] init];
        self.managedObjectContext = [self managedObjectContextInstance];
        /*
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            UIDocument *doc = [[UIDocument alloc] initWithFileURL:[NSURL fileURLWithPath:[GeoDefaults sharedGeoDefaultsInstance].geoDocumentPath isDirectory:YES]];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSURL *cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil];
            NSString* cloudContent = [[cloudURL path] stringByAppendingPathComponent:@"GeoJournal"];
            TRACE("%s, %s, %s\n", __func__, [[cloudURL absoluteString] UTF8String], [cloudContent UTF8String]);
            [fileManager setUbiquitous:YES itemAtURL:doc.fileURL destinationURL:[NSURL fileURLWithPath:cloudContent] error:&error];
            if (error) {
                NSLog(@"%@", error);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                TRACE("%s, folder sync done!\n", __func__);
                //[[NSNotificationCenter defaultCenter] postNotificationName:@"RefetchAllDatabaseData" object:self userInfo:nil];
            });
        });
         */
	}
	
	return self;
}

#pragma mark -
#pragma mark Setting up Cloud
- (void)setupCloud
{
#if ORIGINAL_CODE
    GeoCloudDocument *cloudDoc = [[GeoCloudDocument alloc] initWithFileURL:storeURL];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    // Creating managed document
    // ??? this managed document is somehow connected to the file in the local storage.
    // ??? why does it need to have the option.
    
    cloudDoc.persistentStoreOptions = options;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
        NSLog(@"file exists.");
        [cloudDoc openWithCompletionHandler:^(BOOL success){
            NSLog(@"%s, %d", __func__, success);
            printf("done in file exists.\n");
            if (!success) {
                // Handle the error.
            }
        }];
    }
    else {
        NSLog(@"file doesn't exist.");
        
        [cloudDoc saveToURL:storeURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
            NSLog(@"%s, %d", __func__, success);
            printf("done in file doesn't exist.");
            
            if (!success) {
                // Handle the error.
            }
        }];
    }
#endif
}
#pragma mark -
#pragma mark Core Data stack

- (void)queryDidFinishGathering:(NSNotification *)notification
{
    [self.metaQuery stopQuery];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidFinishGatheringNotification
                                                  object:self.metaQuery];
    TRACE("%s: Result count: %d", __func__, [self.metaQuery resultCount]);
    
    if ([self.metaQuery resultCount] > 0) {
        // Document(s) found by query
        for (int i=0; i<[self.metaQuery resultCount]; i++) {
            // Results are NSMetadataItem instances
            NSMetadataItem *result = [self.metaQuery resultAtIndex:i];
            NSLog(@"Result: %@", [result valuesForAttributes:[result attributes]]);
        }
        
        NSURL *documentFileURL = [[self.metaQuery resultAtIndex:0] valueForAttribute:NSMetadataItemURLKey];
        NSLog(@"%s, %@", __func__, [documentFileURL description]);
        //UIManagedDocument *document = [[UIManagedDocument alloc] initWithFileURL:documentFileURL];
        //[self setMyManagedDocument:document];
        
        //[[self myManagedDocument] openWithCompletionHandler:^(BOOL success) { 
        //    NSLog(@"Open success flag: %d", success);
        //}];
    }
#if 0
    else {
        // No documents found, create one.
        NSURL *localDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *localFileURL = [localDocumentsDirectory URLByAppendingPathComponent:(NSString *)myFilename];
        [self setMyManagedDocument:[[UIManagedDocument alloc] initWithFileURL:localFileURL]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[localFileURL path]]) {
            // Local file already exists
            [[self myManagedDocument] openWithCompletionHandler:^(BOOL success) {
                NSLog(@"Open success flag: %d", success);
            }];
        } else {
            // Local file does not already exist
            [[self myManagedDocument] saveToURL:localFileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                NSLog(@"Save success flag: %d", success);
            }];
        }
        
        NSURL *cloudURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:(NSString *)containerID];
        NSURL *cloudFileURL = [cloudURL URLByAppendingPathComponent:(NSString *)myFilename];
        NSError *setUBError = nil;
        
        if (![[NSFileManager defaultManager] setUbiquitous:YES itemAtURL:localFileURL destinationURL:cloudFileURL error:&setUBError]) {
            NSLog(@"Error setting UB: %@", setUBError);
        }
    }
#endif
}


/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContextInstance {
	TRACE_HERE;
    if (managedObjectContext__ != nil) {
        return managedObjectContext__;
    }
	

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        // Make life easier by adopting the new NSManagedObjectContext concurrency API
        // the NSMainQueueConcurrencyType is good for interacting with views and controllers since
        // they are all bound to the main thread anyway
        NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        
        [moc performBlockAndWait:^{
            // even the post initialization needs to be done within the Block
            [moc setPersistentStoreCoordinator: coordinator];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChangesFrom_iCloud:) 
                                                         name:NSPersistentStoreDidImportUbiquitousContentChangesNotification 
                                                       object:coordinator];
        }];
        managedObjectContext__ = moc;

#ifdef ORIGINAL_CODE
        managedObjectContext__ = [[[NSManagedObjectContext alloc] init] retain];
        [managedObjectContext__ setPersistentStoreCoordinator: coordinator];
#endif
    }

    return managedObjectContext__;
}

// this takes the NSPersistentStoreDidImportUbiquitousContentChangesNotification
// and transforms the userInfo dictionary into something that
// -[NSManagedObjectContext mergeChangesFromContextDidSaveNotification:] can consume
// then it posts a custom notification to let detail views know they might want to refresh.
// The main list view doesn't need that custom notification because the NSFetchedResultsController is
// already listening directly to the NSManagedObjectContext
- (void)mergeiCloudChanges:(NSDictionary*)noteInfo forContext:(NSManagedObjectContext*)moc {
    TRACE_HERE;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableDictionary *localUserInfo = [NSMutableDictionary dictionary];
    
    NSSet* allInvalidations = [noteInfo objectForKey:NSInvalidatedAllObjectsKey];
    NSNotification* refreshNotification = nil;
    
    if (nil == allInvalidations) {
        // (1) we always materialize deletions to ensure delete propagation happens correctly, especially with 
        // more complex scenarios like merge conflicts and undo.  Without this, future echoes may 
        // erroreously resurrect objects and cause dangling foreign keys
        // (2) we always materialize insertions to make new entries visible to the UI
        NSString* materializeKeys[] = { NSDeletedObjectsKey, NSInsertedObjectsKey };
        int c = (sizeof(materializeKeys) / sizeof(NSString*));
        for (int i = 0; i < c; i++) {
            NSSet* set = [noteInfo objectForKey:materializeKeys[i]];
            if ([set count] > 0) {
                NSMutableSet* objectSet = [NSMutableSet set];
                for (NSManagedObjectID* moid in set) {
                    [objectSet addObject:[moc objectWithID:moid]];
                }
                [localUserInfo setObject:objectSet forKey:materializeKeys[i]];
            }
        }
        
        // (3) we do not materialize updates to objects we are not currently using
        // (4) we do not materialize refreshes to objects we are not currently using
        // (5) we do not materialize invalidations to objects we are not currently using
        NSString* noMaterializeKeys[] = { NSUpdatedObjectsKey, NSRefreshedObjectsKey, NSInvalidatedObjectsKey };
        c = (sizeof(noMaterializeKeys) / sizeof(NSString*));
        for (int i = 0; i < 2; i++) {
            NSSet* set = [noteInfo objectForKey:noMaterializeKeys[i]];
            if ([set count] > 0) {
                NSMutableSet* objectSet = [NSMutableSet set];
                for (NSManagedObjectID* moid in set) {
                    NSManagedObject* realObj = [moc objectRegisteredForID:moid];
                    if (realObj) {
                        [objectSet addObject:realObj];
                    }
                }
                [localUserInfo setObject:objectSet forKey:noMaterializeKeys[i]];
            }
        }
        
        NSNotification *fakeSave = [NSNotification notificationWithName:NSManagedObjectContextDidSaveNotification object:self  userInfo:localUserInfo];
        [moc mergeChangesFromContextDidSaveNotification:fakeSave]; 
        
    } else {
        [localUserInfo setObject:allInvalidations forKey:NSInvalidatedAllObjectsKey];
    }
    
    [moc processPendingChanges];
    
    refreshNotification = [NSNotification notificationWithName:@"RefreshAllViews" object:self  userInfo:localUserInfo];
    
    [[NSNotificationCenter defaultCenter] postNotification:refreshNotification];
    [pool drain];
}
// NSNotifications are posted synchronously on the caller's thread
// make sure to vector this back to the thread we want, in this case
// the main thread for our views & controller
- (void)mergeChangesFrom_iCloud:(NSNotification *)notification {
    TRACE_HERE;
    NSDictionary* ui = [notification userInfo];
	NSManagedObjectContext* moc = [self managedObjectContext];
    
    // this only works if you used NSMainQueueConcurrencyType
    // otherwise use a dispatch_async back to the main thread yourself
    [moc performBlock:^{
        [self mergeiCloudChanges:ui forContext:moc];
    }];
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel__ != nil) {
        return managedObjectModel__;
    }
	TRACE_HERE;
	NSString *path = [[NSBundle mainBundle] pathForResource:@"GeoJournal"ofType:@"momd"];
	NSURL *momURL = [NSURL fileURLWithPath:path];
	managedObjectModel__ = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
	
    //managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel__;
}

/*
 - (void)checkMigration
 {
 NSError *error = nil;
 
 NSPersistentStoreCoordinator *psc = [self persistentStoreCoordinator];
 NSURL *sourceStoreURL = [NSURL fileURLWithPath: [[[GeoDefaults sharedGeoDefaultsInstance] applicationDocumentsDirectory] 
 stringByAppendingPathComponent: @"GeoJournal.sqlite"]];
 
 NSURL *destStoreURL = [NSURL fileURLWithPath: [[[GeoDefaults sharedGeoDefaultsInstance] applicationDocumentsDirectory] 
 stringByAppendingPathComponent: @"GeoJournal2.sqlite"]];		
 
 NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType 
 URL:sourceStoreURL
 error:&error];
 NSString *path = [[NSBundle mainBundle] pathForResource:@"GeoJournal" ofType:@"mom"];
 NSURL *url = [NSURL fileURLWithPath:path];
 
 NSManagedObjectModel *sourceModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
 if (error) {
 NSLog(@"%s, %@", __func__, error);
 return;
 }
 
 path = [[NSBundle mainBundle] pathForResource:@"GeoJournal 2" ofType:@"mom"];
 url = [NSURL fileURLWithPath:path];
 NSManagedObjectModel *destinationModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
 BOOL pscCompatibile = [destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
 
 if (pscCompatibile) {
 // no need to migrate
 TRACE("%s, No need to migrate.\n", __func__);
 return;
 }
 
 NSDictionary *destMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType 
 URL:destStoreURL 
 error:&error];
 
 
 NSManagedObjectModel *destModel = [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:destMetadata];
 if (error) {
 NSLog(@"%s, %@", __func__, error);
 return;
 }
 
 NSMappingModel *mapping = [NSMappingModel mappingModelFromBundles:nil forSourceModel:sourceModel destinationModel:destModel];
 
 NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:destModel];
 
 BOOL ok = [manager migrateStoreFromURL:sourceStoreURL 
 type:nil 
 options:nil
 withMappingModel:mapping
 toDestinationURL:destStoreURL 
 destinationType:nil 
 destinationOptions:nil
 error:&error];
 
 if (ok) {
 NSLog(@"Migration succeeded.\n");
 }
 else {
 NSLog(@"Migration failed: %@", error);
 }
 
 
 }
 */

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator__ != nil) {
        return persistentStoreCoordinator__;
    }
	
    persistentStoreCoordinator__ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
    // prep the store path and bundle stuff here since NSBundle isn't totally thread safe
    NSPersistentStoreCoordinator* psc = persistentStoreCoordinator__;
    NSURL *storeUrl = [NSURL fileURLWithPath: [[[GeoDefaults sharedGeoDefaultsInstance] applicationDocumentsDirectory] 
                                        stringByAppendingPathComponent: @"GeoJournal.sqlite"]];
    //NSString* bundleid = [[[NSBundle mainBundle] bundleIdentifier] lowercaseString];
    //NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"GeoJournal" ofType:@"sqlite"];

    // do this asynchronously since if this is the first time this particular device is syncing with preexisting
    // iCloud content it may take a long long time to download
    // CTODO: this has to be blocked call???
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        NSURL *cloudURL = [[GeoDefaults sharedGeoDefaultsInstance] getCloudContainer];
        
        NSString* coreDataCloudContent = [[cloudURL path] stringByAppendingPathComponent:@"GeoJournalDB"];
        
        TRACE("%s, %s, %s\n", __func__, [[cloudURL absoluteString] UTF8String], [coreDataCloudContent UTF8String]);
        TRACE("%s\n", [[storeUrl absoluteString] UTF8String]);
        
        if (cloudURL) {
            cloudURL = [NSURL fileURLWithPath:coreDataCloudContent];
            
            //  The API to turn on Core Data iCloud support here.
            NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"com.odinasoftware.igeojournal", NSPersistentStoreUbiquitousContentNameKey, 
                                     cloudURL, NSPersistentStoreUbiquitousContentURLKey, 
                                     [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, 
                                     [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,nil];
            
            // Needed on iOS seed 3, but not Mac OS X
            //[self workaround_weakpackages_9653904:options];
            
            NSError *error = nil;
            
            [psc lock];
            if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
                /*
                 Replace this implementation with code to handle the error appropriately.
                 
                 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
                 
                 Typical reasons for an error here include:
                 * The persistent store is not accessible
                 * The schema for the persistent store is incompatible with current managed object model
                 Check the error message to determine what the actual problem was.
                 */
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }    
            [psc unlock];
            
            // tell the UI on the main thread we finally added the store and then
            // post a custom notification to make your views do whatever they need to such as tell their
            // NSFetchedResultsController to -performFetch again now there is a real store
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"asynchronously added persistent store!");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RefetchAllDatabaseData" object:self userInfo:nil];
            });
        }
        else {
            // TODO: tell users that iCloud is not enabled. 
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                     [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
            
            NSError *error=nil;
            
            
            if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
                // Handle the error.
                NSLog(@"Error in persistent store: %@", error);
            }   
        }
    }
    //);

	TRACE("%s, returning, db: %s\n", __func__, [[storeUrl absoluteString] UTF8String]);
#ifdef ORIGINAL_CODE
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
	NSError *error=nil;
    
    
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Handle the error.
		NSLog(@"Error in persistent store: %@", error);
    }   
#endif
        
    return persistentStoreCoordinator__;
}

#pragma mark MAIL RECIPIENT
- (NSMutableArray*)mailRecipientArray
{
	if (mailRecipientArray == nil) {
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"MailRecipients" inManagedObjectContext:self.managedObjectContext];
		[request setEntity:entity];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[request setSortDescriptors:sortDescriptors];
		[sortDescriptors release];
		[sortDescriptor release];
		
		NSError *error;
		NSMutableArray* mutableFetchResults = [[managedObjectContext__ executeFetchRequest:request error:&error] mutableCopy];
		if (mutableFetchResults == nil) {
			// Handle the error.
			NSLog(@"%s, %@", __func__, error);
		}
		
		mailRecipientArray = mutableFetchResults;
		[mailRecipientArray retain];
		
		[mutableFetchResults release];
		[request release];	
		
	}
	
	return mailRecipientArray;
}

- (MailRecipients*)mailRecipient 
{
	return (MailRecipients *)[NSEntityDescription insertNewObjectForEntityForName:@"MailRecipients" inManagedObjectContext:managedObjectContext__];
}

- (NSString*)defaultRecipient
{
	NSString *s = nil;
	
	for (MailRecipients* r in self.mailRecipientArray) {
		if ([r.selected boolValue] == YES) {
			s = r.mailto;
			break;
		}
	}
	
	return s;
}

#pragma mark -
#pragma mark CATEGORY DB

- (NSMutableArray*)categoryArray
{
	if (categoryArray == nil) {
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:self.managedObjectContext];
		[request setEntity:entity];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[request setSortDescriptors:sortDescriptors];
		[sortDescriptors release];
		[sortDescriptor release];
		
		NSError *error;
		NSMutableArray* mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
		if (mutableFetchResults == nil) {
			// Handle the error.
			NSLog(@"%s, %@", __func__, error);
		}
		
		
		categoryArray = mutableFetchResults;
		[categoryArray retain];
		
		[mutableFetchResults release];
		[request release];
	}
	
	return categoryArray;
}

- (GCategory*)categoryEntity 
{
	return (GCategory*) [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.managedObjectContext];
}

- (DefaultCategory*)defaultCategoryEntity
{
	return (DefaultCategory *)[NSEntityDescription insertNewObjectForEntityForName:@"DefaultCategory" inManagedObjectContext:self.managedObjectContext];
}

- (Journal*)journalEntity
{
	return (Journal *)[NSEntityDescription insertNewObjectForEntityForName:@"Journal" inManagedObjectContext:self.managedObjectContext];
}

- (PictureFrame*)pictureFrameEntity
{
	return (PictureFrame*)[NSEntityDescription insertNewObjectForEntityForName:@"PictureFrame" inManagedObjectContext:self.managedObjectContext];
}

- (Pictures*)picturesEntity
{
	return (Pictures*)[NSEntityDescription insertNewObjectForEntityForName:@"Pictures" inManagedObjectContext:self.managedObjectContext];
}

- (NSArray*)journalByCategory:(GCategory*)category
{
	BOOL reload = NO;
	NSArray *array = [self.journalDict objectForKey:category.name];
	
	if (array != nil) {
		// check the integrity of it
		if ([array count] != [category.contents count]) {
			reload = YES;
		}
	}
	
	if (array == nil || reload == YES) {
		TRACE("%s, journal array created.\n", __func__);
		// Not existed yet, create and register it.
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		array = [[category.contents allObjects] sortedArrayUsingDescriptors:sortDescriptors];
		[sortDescriptors release];
		[sortDescriptor release];
		
		[self.journalDict setObject:array forKey:category.name];
	}
	
	return array;
}

- (NSMutableArray*)picturesForJournal:(NSString*)journalPicture
{
	NSMutableArray *picturesString = nil;
		
	@try {
		TRACE("%s, finding pictures for %s\n", __func__, [journalPicture UTF8String]);
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"frame.picture == %@", journalPicture];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Pictures" inManagedObjectContext:self.managedObjectContext];
		
		[request setEntity:entity];
		[request setPredicate:predicate];
		[request setPropertiesToFetch:[NSArray arrayWithObjects:@"picture", nil]];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[request setSortDescriptors:sortDescriptors];
		[sortDescriptors release];
		[sortDescriptor release];
		
		NSError *error=nil;
		NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
		if (error){
			// Handle the error.
			NSLog(@"%s, %@", __func__, error);
		}
		else if (array && [array count] > 0) {
			picturesString = [[NSMutableArray alloc] initWithCapacity:[array count]];
			for (Pictures *p in array) {
				NSString *tmp = p.picture; //getThumbnailFilename(p.picture);
				NSLog(@"--- %s ----\n", [tmp UTF8String]);
				[picturesString addObject:tmp];
				//[tmp release];
			}
		}
	
		[request release];
	}
	@catch (NSException * e) {
		NSLog(@"%s, %@", __func__, [e reason]);
	}	
		
	return picturesString;
}

- (void)savePicture:(NSString*)picture toJournal:(Journal*)journal 
{
	PictureFrame *frame = nil;
	NSFetchRequest *request = nil;
	
	@try {
		TRACE("%s, will save picture %s at %s\n", __func__, [picture UTF8String], [journal.picture UTF8String]);
		request = [[NSFetchRequest alloc] init];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"picture == %@", journal.picture];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"PictureFrame" inManagedObjectContext:self.managedObjectContext];
		[request setEntity:entity];
		[request setPredicate:predicate];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[request setSortDescriptors:sortDescriptors];
		[sortDescriptors release];
		[sortDescriptor release];
		
		NSError *error=nil;
		NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
		if (error){
			// Handle the error.
			NSLog(@"%s, %@", __func__, error);
		}
		else if (array && [array count] > 0) {
			if ([array count] > 1) {
				NSLog(@"%s, more than one entries found: %d", __func__, [array count]);
			}
			frame = [array objectAtIndex:0];
		}
		
		if (frame == nil) {
			// Should create one for this picture
			TRACE("%s, Frame does not exist for %s\n", __func__, [journal.picture UTF8String]);
			frame = [self pictureFrameEntity];
			frame.creationDate = [NSDate date];
			frame.picture = journal.picture;
		}
		
		Pictures *aPicture = [self picturesEntity];
		aPicture.creationDate = [NSDate date];
		aPicture.picture = picture;
		aPicture.frame = frame;
		
		[frame addPicturesObject:aPicture];
		[self save];
	}
	@catch (NSException * e) {
		NSLog(@"%s, %@", __func__, e);
	}
	@finally {
		[request release];
	}
}

- (BOOL)removePicture:(NSString*)picture fromJournal:(Journal*)journal deleteFile:(BOOL)shouldDeleteFile
{
	PictureFrame *frame = nil;
	NSFetchRequest *request = nil;
	BOOL rs = TRUE;
	
	@try {
		TRACE("%s, removing pictures for %s\n", __func__, [picture UTF8String]);
		request = [[NSFetchRequest alloc] init];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"picture == %@", journal.picture];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"PictureFrame" inManagedObjectContext:self.managedObjectContext];
		[request setEntity:entity];
		[request setPredicate:predicate];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[request setSortDescriptors:sortDescriptors];
		[sortDescriptors release];
		[sortDescriptor release];
		
		NSError *error=nil;
		NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
		if (error){
			// Handle the error.
			NSLog(@"%s, %@", __func__, error);
			rs = FALSE;
		}
		else if (array && [array count] > 0) {
			frame = [array objectAtIndex:0];
			
			for (Pictures *p in frame.pictures) {
				if ([picture compare:p.picture] == 0) {
					// remove this one.
					if (shouldDeleteFile) {
						remove_file([[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:p.picture]);
					}
					
					[self deleteObject:p];
					//[frame removePicturesObject:p];
					TRACE("%s, removing one picture: %s\n", __func__, [picture UTF8String]);
					rs = TRUE;
					break;
				}
			}
		}
		
		[request release];
		if (rs) 
			[self save];
	}
	@catch (NSException * e) {
		NSLog(@"%s, %@", __func__, [e reason]);
	}	
	
	return rs;
}

- (void)removeJournalPicture:(Journal*)journal
{
	remove_file([[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:journal.picture]);
	journal.picture = nil;
	
	[self save];
}

- (void)replacePicture:(NSString*)picture forJournal:(Journal*)journal
{
	PictureFrame *frame = [self getFrameForJournal:journal];
	remove_file([[GeoDefaults sharedGeoDefaultsInstance] getAbsoluteDocPath:journal.picture]);
	
	journal.picture = picture;
	frame.picture = picture;
	
	[self save];
}

- (PictureFrame*)getFrameForJournal:(Journal*)journal
{
	PictureFrame *frame = nil;
	NSFetchRequest *request = nil;
	
	@try {
		request = [[NSFetchRequest alloc] init];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"picture == %@", journal.picture];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"PictureFrame" inManagedObjectContext:self.managedObjectContext];
		[request setEntity:entity];
		[request setPredicate:predicate];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[request setSortDescriptors:sortDescriptors];
		[sortDescriptors release];
		[sortDescriptor release];
		
		NSError *error=nil;
		NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
		if (error){
			// Handle the error.
			NSLog(@"%s, %@", __func__, error);
		}
		else if (array && [array count] > 0) {
			if ([array count] > 1) {
				NSLog(@"%s, more than one entries found: %d", __func__, [array count]);
			}
			frame = [array objectAtIndex:0];
		}
		
	}
	@catch (NSException * e) {
		NSLog(@"%s, %@", __func__, e);
	}
	@finally {
		[request release];
	}
	
	return frame;
}

- (NSString*)makeUUIDFileName:(NSString*) filename
{   
    if (filename == NULL)
        return NULL;

    NSString *actual=NULL;
    NSRange range = [filename rangeOfString:@"/"];
    if (range.location == NSNotFound) {
        actual = [NSString stringWithFormat:@"%@/%@", [GeoDefaults sharedGeoDefaultsInstance].UUID, filename];
    }
        
    return actual;

}
                  
- (void)upgradeDBForCloudReady
{
    if ([[GeoDefaults sharedGeoDefaultsInstance].dbReadyForCloud boolValue]) {
        TRACE("%s, db is ready for cloud.\n", __func__);
        return;
    }
        
    @try {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Journal" inManagedObjectContext:self.managedObjectContext];
        [request setEntity:entity];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [request setSortDescriptors:sortDescriptors];
        [sortDescriptors release];
        [sortDescriptor release];
        
        NSError *error;
        NSMutableArray* mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
        if (mutableFetchResults == nil) {
            // Handle the error.
            NSLog(@"%s, %@", __func__, error);
            return;
        }
        
        [request release];
        TRACE("%s: # of entries: %d\n", __func__, [mutableFetchResults count]);
        NSString *temp;
        for (Journal *journal in mutableFetchResults) {
            TRACE("Db: %p, Journal: %s, audio: %s\n", journal, [journal.picture UTF8String], [journal.audio UTF8String]);
            
            if ((temp = [self makeUUIDFileName:journal.picture])) {
                [journal setPicture:temp];
            }
            if ((temp = [self makeUUIDFileName:journal.audio])) {
                [journal setAudio:temp];
            }
                      
            
            TRACE("Journal: %s, audio: %s\n", [journal.picture UTF8String], [journal.audio UTF8String]);
            // Get frame
            PictureFrame *frame = [self getFrameForJournal:journal];
            
            if (frame) {
                TRACE("frame: %s\n", [frame.picture UTF8String]);
                
                // Get pictures for the frame
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"frame.picture == %@", journal.picture];
                
                NSEntityDescription *entity = [NSEntityDescription entityForName:@"Pictures" inManagedObjectContext:self.managedObjectContext];
                
                request = [[NSFetchRequest alloc] init];
                [request setEntity:entity];
                [request setPredicate:predicate];
                [request setPropertiesToFetch:[NSArray arrayWithObjects:@"picture", nil]];
                
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
                NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
                [request setSortDescriptors:sortDescriptors];
                [sortDescriptors release];
                [sortDescriptor release];
                
                NSError *error=nil;
                NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
                if (error){
                    // Handle the error.
                    NSLog(@"%s, %@", __func__, error);
                }
                else if (array && [array count] > 0) {
                    TRACE("----------\n");
                    for (Pictures *p in array) {
                        TRACE("[%s] ", [p.picture UTF8String]);
                        p.picture = [self makeUUIDFileName:p.picture];
                    }
                    TRACE("\n----------\n");
                }
                
                if ((temp = [self makeUUIDFileName:frame.picture])) {
                    [frame setPicture:temp];
                }

                
                [request release];
            }
           
        }
        
        [self save];
        
        NSNumber *on = [NSNumber numberWithBool:TRUE];
        [GeoDefaults sharedGeoDefaultsInstance].dbReadyForCloud = on;
    }
	@catch (NSException * e) {
		NSLog(@"%s, %@", __func__, [e reason]);
	}	
    
       
}

#pragma mark JOURNAL DB

- (void)deleteJournalObject:(Journal*)journal forCategory:(GCategory*)category 
{
	[category removeContentsObject:journal];
	[self deleteObject:journal];
	[self save];
}

#pragma mark -
#pragma mark -
#pragma mark GENERAL DB functions
- (void)save
{
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"%s, %@", __func__, error);
	}
}

- (void)deleteObject:(NSManagedObject*)object
{
	[self.managedObjectContext deleteObject:object];
	[self save];
}

#pragma mark -

- (void)dealloc {
	[mailRecipientArray release];
	[journalDict release];
	
	[super dealloc];
}	

@end
