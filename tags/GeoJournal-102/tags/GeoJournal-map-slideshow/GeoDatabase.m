//
//  GeoDatabase.m
//  GeoJournal
//
//  Created by Jae Han on 7/8/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "GeoDatabase.h"
#import "GeoDefaults.h"
#import "MailRecipients.h"

static GeoDatabase	*sharedGeoDatabase = nil;

@implementation GeoDatabase

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
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


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
	
	NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
        // Handle the error.
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

#pragma mark -
#pragma mark GENERAL DB functions
- (void)save
{
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"%s, $@", __func__, error);
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
	
	[super dealloc];
}	

@end
