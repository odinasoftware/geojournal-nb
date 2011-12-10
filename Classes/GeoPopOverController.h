//
//  GeoPopOverController.h
//  GeoJournal
//
//  Created by Jae Han on 11/30/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteViewController.h"

@interface GeoPopOverController : UINavigationController {
    id <ChangeCategory>     delegate;
}

@property (nonatomic, retain)   id<ChangeCategory>  delegate;
    
@end
