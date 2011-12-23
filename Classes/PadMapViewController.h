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
#import "MapViewCommonController.h"

@interface PadMapViewController : MapViewCommonController { 
    // Toobar support   
    UIBarButtonItem             *categoryBar;
    UIBarButtonItem             *searchBar;
    UIBarButtonItem             *settingBar;
    UIBarButtonItem             *composeBar;
    UIBarButtonItem             *viewsBar;
    UILabel                     *titleLabel;
}

@property (nonatomic, retain)   IBOutlet    UIBarButtonItem             *categoryBar;
@property (nonatomic, retain)   IBOutlet    UIBarButtonItem             *searchBar;
@property (nonatomic, retain)   IBOutlet    UIBarButtonItem             *settingBar;
@property (nonatomic, retain)   IBOutlet    UIBarButtonItem             *composeBar;
@property (nonatomic, retain)   IBOutlet    UIBarButtonItem             *viewsBar;
@property (nonatomic, retain)   IBOutlet    UILabel                     *titleLabel;

@end
