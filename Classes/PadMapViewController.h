//
//  PadMapViewController.h
//  GeoJournal
//
//  Created by Jae Han on 12/7/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import <MapKit/MKReverseGeocoder.h>

@interface PadMapViewController : UIViewController <MKMapViewDelegate> {
    MKMapView       *mapView;
}

@property (nonatomic, retain)   IBOutlet    MKMapView   *mapView;

@end
