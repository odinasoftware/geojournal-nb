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
@synthesize storeURL;
@synthesize metaQuery;

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
	}
	
	return self;
}

#pragma mark -
#pragma mark Setting up Cloud
- (void)setupCloud
{
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

// NSNotifications are posted synchronously on the caller's thread
// make sure to vector this back to the thread we want, in this case
// the main thread for our views & controller
- (void)mergeChangesFrom_iCloud:(NSNotification *)notification {
    NSDictionary* ui = [notification userInfo];
	NSManagedObjectContext* moc = [self managedObjectContext];
    
    // this only works if you used NSMainQueueConcurrencyType
    // otherwise use a dispatch_async back to the main thread yourself
    [moc performBlock:^{
        // TODO: need to work on it later
        //[self mergeiCloudChanges:ui forContext:moc];
    }];
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
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
    
#if 0
    /*
    storeURL = [NSURL fileURLWithPath: [[[GeoDefaults sharedGeoDefaultsInstance] applicationDocumentsDirectory] 
                                               stringByAppendingPathComponent: @"GeoJournal.sqlite"]];
    NSURL *cloudURL = [[[[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:UBIQUITY_CONTAINER_URL] URLByAppendingPathComponent:@"Documents"] 
                       URLByAppendingPathComponent:@"GeoJournal.sqlite"];
    
	TRACE("%s, db: %s\n", __func__, [[storeURL absoluteString] UTF8String]);
    TRACE("%s, cloud URL: %s\n", __func__, [[cloudURL absoluteString] UTF8String]);
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, 
                             cloudURL, NSPersistentStoreUbiquitousContentURLKey,
                             @"GeoJournal.sqlite", NSPersistentStoreUbiquitousContentNameKey, nil];
    
    // Creating managed document
    // ??? this managed document is somehow connected to the file in the local storage.
    // ??? why does it need to have the option.
    
    GeoCloudDocument *doc = [[GeoCloudDocument alloc] initWithFileURL:storeURL];
    doc.persistentStoreOptions = options;
    
        
    //[doc.managedObjectContext performBlockAndWait:^() {
    //    NSLog(@"managed object created."); 
    //}];
    //sleep(10);
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
        [doc openWithCompletionHandler:^(BOOL success){
            if (!success) {
                // Handle the error.
                NSLog(@"failed in opening.");
            }
        }];
    }
    else {
        [doc saveToURL:storeURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
            if (!success) {
                // Handle the error.
                NSLog(@"failed in save for creating.");
            }
        }];
    }
    
    NSError *error=nil;
    
    if (![doc configurePersistentStoreCoordinatorForURL:storeURL ofType:NSSQLiteStoreType modelConfiguration:nil storeOptions:options error:&error]) {
        NSLog(@"Error in persistent store: %@", error);
        return nil;
    }

    managedObjectContext = doc.managedObjectContext;
    managedDocument = doc;

    TRACE("%s, filetype: %s, %s\n", __func__, [doc.fileType UTF8String], [[doc.fileURL absoluteString] UTF8String]);
    
    // Look for this is in the cloud or not
    NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
    //[self setDocumentQuery:query];
    [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
    [query setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", NSMetadataItemFSNameKey, @"GeoJournal.sqlite"]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryDidFinishGathering:) name:NSMetadataQueryDidFinishGatheringNotification object:query];
    [query startQuery];
    
    metaQuery = query;
    [query release];
    

    
    //[[NSFileManager defaultManager] setUbiquitous:YES itemAtURL:storeURL destinationURL:cloudURL error:&error];
    //if (error) {
    //    NSLog(@"%s, %@", __func__, [error description]);
    //}
  
    [doc release];
    
    //[self setupCloud];
     */
#endif
    
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel__ != nil) {
        return managedObjectModel__;
    }
	
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
	
    storeURL = [NSURL fileURLWithPath: [[[GeoDefaults sharedGeoDefaultsInstance] applicationDocumentsDirectory] 
														stringByAppendingPathComponent: @"GeoJournal.sqlite"]];
	TRACE("%s, db: %s\n", __func__, [[storeURL absoluteString] UTF8String]);
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    // Creating managed document
    // ??? this managed document is somehow connected to the file in the local storage.
    // ??? why does it need to have the option.
    /*
    UIManagedDocument *doc = [[UIManagedDocument alloc] initWithFileURL:storeUrl];
    doc.persistentStoreOptions = options;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[storeUrl path]]) {
        [doc openWithCompletionHandler:^(BOOL success){
            if (!success) {
                // Handle the error.
                NSLog(@"failed in opening.");
            }
        }];
    }
    else {
        [doc saveToURL:storeUrl forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
            if (!success) {
                // Handle the error.
                NSLog(@"failed in save for creating.");
            }
        }];
    }
	
    //[doc.managedObjectContext performBlockAndWait:^() {
    //    NSLog(@"Here, created.");
    //}];
     */
    
	NSError *error=nil;
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Handle the error.
		NSLog(@"Error in persistent store: %@", error);
    }   
    
        
    return persistentStoreCoordinator;
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
		NSMutableArray* mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
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
	return (MailRecipients *)[NSEntityDescription insertNewObjectForEntityForName:@"MailRecipients" inManagedObjectContext:managedObjectContext];
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
