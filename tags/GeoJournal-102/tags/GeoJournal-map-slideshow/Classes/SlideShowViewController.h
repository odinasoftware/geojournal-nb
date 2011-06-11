//
//  SlideShowViewController.h
//  GeoJournal
//
//  Created by Jae Han on 7/20/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SlideShowViewController : UIViewController {
	IBOutlet UIScrollView		*_scrollView;
}

@property (nonatomic, retain) UIScrollView	*_scrollView;

@end
