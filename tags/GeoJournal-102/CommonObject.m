//
//  CommonObject.m
//  GeoJournal
//
//  Created by Jae Han on 7/3/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "CommonObject.h"

static CommonObject *sharedCommonObject = nil;

@implementation CommonObject

@synthesize calendar;

+ (CommonObject*)sharedCommonObjectInstance
{
	//@synchronized (self) {
	if (sharedCommonObject == nil) {
		[[self alloc] init];
	}
	//}
	return sharedCommonObject;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedCommonObject == nil) { 
			sharedCommonObject = [super allocWithZone:zone]; 
			return sharedCommonObject; // assignment and return on first allocation 
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

- (id)init
{
	if (self = [super init]) {
		calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	}
	
	return self;
}


@end
