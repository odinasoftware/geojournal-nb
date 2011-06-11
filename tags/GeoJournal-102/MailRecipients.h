//
//  MailRecipients.h
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface MailRecipients :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * mailto;
@property (nonatomic, retain) NSNumber * selected;
@property (nonatomic, retain) NSDate * creationDate;

@end



