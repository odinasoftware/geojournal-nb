//
//  Pictures.h
//  GeoJournal
//
//  Created by Jae Han on 10/6/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <CoreData/CoreData.h>

@class PictureFrame;

@interface Pictures :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * picture;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) PictureFrame * frame;

@end



