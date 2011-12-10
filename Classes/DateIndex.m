//
//  DateIndex.m
//  GeoJournal
//
//  Created by Jae Han on 11/7/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "DateIndex.h"

@implementation DateIndex

@synthesize dateString;
@synthesize index;

- (void)dealloc
{
	[dateString release];
	[super dealloc];
}

@end
