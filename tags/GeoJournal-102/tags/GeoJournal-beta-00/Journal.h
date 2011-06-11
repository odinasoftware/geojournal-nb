//
//  Journal.h
//  GeoJournal
//
//  Created by Jae Han on 7/6/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Journal :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * audio;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * picture;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;

@end



