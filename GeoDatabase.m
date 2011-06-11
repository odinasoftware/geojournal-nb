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
#import "Category.h"
#import "Journal.h"
#import "GeoJournalHeaders.h"
#import "PictureFrame.h"
#import "Pictures.h"

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

int change_file_name_to(NSString *from, NSString *to) 
{
	
}

@implementation GeoDatabase

@synthesize journalDict;

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
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[[NSManagedObjectContext alloc] init] retain];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"GeoJournal"ofType:@"momd"];
	NSURL *momURL = [NSURL fileURLWithPath:path];
	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
	
    //managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
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
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSURL *storeUrl = [NSURL fileURLWithPath: [[[GeoDefaults sharedGeoDefaultsInstance] applicationDocumentsDirectory] 
														stringByAppendingPathComponent: @"GeoJournal.sqlite"]];
	TRACE("%s, db: %s\n", __func__, [[storeUrl absoluteString] UTF8String]);
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	NSError *error=nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
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

- (Category*)categoryEntity 
{
	return (Category*) [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.managedObjectContext];
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

- (NSArray*)journalByCategory:(Category*)category
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

- (void)deleteJournalObject:(Journal*)journal forCategory:(Category*)category 
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
