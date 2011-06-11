//
//  PictureFrame.h
//  GeoJournal
//
//  Created by Jae Han on 10/6/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Pictures;

@interface PictureFrame :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * picture;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSSet* pictures;

@end


@interface PictureFrame (CoreDataGeneratedAccessors)
- (void)addPicturesObject:(Pictures *)value;
- (void)removePicturesObject:(Pictures *)value;
- (void)addPictures:(NSSet *)value;
- (void)removePictures:(NSSet *)value;

@end

