// 
//  Category.m
//  GeoJournal
//
//  Created by Jae Han on 7/6/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "Category.h"

#import "Journal.h"

/*
 Managed object is an object represenation of a record in a table in a database. 
 Managed objects represent the data you operate on in your application. 
 Managed object represents a single object space, or scratch pad, in an application. 
 Its primary responsibility is to manage a collection of managed objects. 
 
 When you create a new managed object, you insert it into a context.
 You fetch existing records in the database into the context as managed objects.
 */
@implementation Category 

@dynamic name;
@dynamic contents;
@dynamic creationDate;

@end
