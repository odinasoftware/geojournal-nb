//
//  ShowDisplayOptionsView.h
//  GeoJournal
//
//  Created by Jae Han on 12/6/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChangeDisplayViewDelegate <NSObject>

- (void)changeDisplayView:(NSInteger)viewIndex;
- (void)dissmissDisplayViewPopover:(id)sender;
@end

@interface ShowDisplayOptionsView : UITableViewController {
    id<ChangeDisplayViewDelegate>   delegate;
    NSArray                         *optionsArray;
}

@property (nonatomic, retain)   id<ChangeDisplayViewDelegate>   delegate;
@property (nonatomic, retain)   NSArray                         *optionsArray;

@end
