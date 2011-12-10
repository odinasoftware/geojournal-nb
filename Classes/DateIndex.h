//
//  DateIndex.h
//  GeoJournal
//
//  Created by Jae Han on 11/7/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateIndex : NSObject
{
	NSString	*dateString;
	NSInteger	index;
}

@property (nonatomic, retain) NSString		*dateString;
@property (nonatomic) NSInteger				index;


@end
