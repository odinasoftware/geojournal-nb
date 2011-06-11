//
//  ParkPlaceMark.h
//  MapTest
//
//  Created by Jae Han on 5/6/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface GeoMark : NSObject<MKAnnotation> {
	CLLocationCoordinate2D	coordinate;
}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)c;
- (NSString*)subtitle;
- (NSString*)title;

@end
