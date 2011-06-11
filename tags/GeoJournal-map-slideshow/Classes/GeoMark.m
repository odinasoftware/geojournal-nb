//
//  ParkPlaceMark.m
//  MapTest
//
//  Created by Jae Han on 5/6/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "GeoMark.h"


@implementation GeoMark
@synthesize coordinate;

- (NSString*)subtitle {
	return @"";
}

- (NSString*)title {
	//NSLog(@"%s", __func__);
	return @"You're here.";
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)c {
	if (self = [super init]) {
		coordinate = c;
	}
	return self;
}
@end
