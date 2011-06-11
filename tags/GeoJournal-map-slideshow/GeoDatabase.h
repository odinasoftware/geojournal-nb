//
//  GeoDatabase.h
//  GeoJournal
//
//  Created by Jae Han on 7/8/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MailRecipients;
@class Category;
@class DefaultCategory;
@class Journal;

@interface GeoDatabase : NSObject {
	// For management
	NSPersistentStoreCoordinator	*persistentStoreCoordinator;
    NSManagedObjectModel			*managedObjectModel;
    NSManagedObjectContext			*managedObjectContext;	    
	
	// MAIL Database entities
	NSMutableArray					*mailRecipientArray;
	MailRecipients					*mailRecipient;
	NSString						*defaultRecipient;
	
	// Category DB entities
	NSMutableArray					*categoryArray;
	Category						*categoryEntity;
	DefaultCategory					*defaultCategoryEntity;
	
	// Journal entities
	Journal							*journalEntity;
}

@property (nonatomic, retain, readonly)	NSManagedObjectModel			*managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext			*managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator	*persistentStoreCoordinator;

@property (nonatomic, retain, readonly) NSMutableArray	*mailRecipientArray;
@property (nonatomic, readonly) MailRecipients			*mailRecipient;
@property (nonatomic, readonly) NSString				*defaultRecipient;

@property (nonatomic, retain, readonly) NSMutableArray	*categoryArray;
@property (nonatomic, readonly) Category				*categoryEntity;
@property (nonatomic, readonly) DefaultCategory			*defaultCategoryEntity;
@property (nonatomic, readonly) Journal					*journalEntity;

// Class definitions
+ (GeoDatabase*)sharedGeoDatabaseInstance;

// Methods
- (void)save;
- (void)deleteObject:(NSManagedObject*)object;

@end
