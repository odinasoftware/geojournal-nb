//
//  Category.h
//  GeoJournal
//
//  Created by Jae Han on 7/6/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Journal;

@interface Category :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate *creationDate;
@property (nonatomic, retain) NSSet* contents;

@end


@interface Category (CoreDataGeneratedAccessors)
- (void)addContentsObject:(Journal *)value;
- (void)removeContentsObject:(Journal *)value;
- (void)addContents:(NSSet *)value;
- (void)removeContents:(NSSet *)value;

@end

