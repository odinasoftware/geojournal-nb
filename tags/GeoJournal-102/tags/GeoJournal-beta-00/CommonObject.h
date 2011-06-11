//
//  CommonObject.h
//  GeoJournal
//
//  Created by Jae Han on 7/3/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CommonObject : NSObject {
	NSCalendar				*calendar;
}

@property (nonatomic, retain) NSCalendar *calendar;

+ (CommonObject*)sharedCommonObjectInstance;

@end
