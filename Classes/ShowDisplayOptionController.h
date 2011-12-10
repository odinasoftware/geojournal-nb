//
//  ShowDisplayOptionController.h
//  GeoJournal
//
//  Created by Jae Han on 12/6/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChangeDisplayViewDelegate;

@interface ShowDisplayOptionController : UINavigationController {
    id<ChangeDisplayViewDelegate>   bypassDelegate;
}

@property (nonatomic, assign) id<ChangeDisplayViewDelegate>     bypassDelegate;

@end
