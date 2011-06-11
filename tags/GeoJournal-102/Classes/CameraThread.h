//
//  CameraThread.h
//  GeoJournal
//
//  Created by Jae Han on 9/5/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CameraThread : NSThread {
	
	@private
	NSCondition					*doSomething;
	UIImagePickerController		*_cameraController;
	UIViewController			*_viewController;

}

@property (nonatomic, retain) UIImagePickerController	*_cameraController;
@property (nonatomic, retain) UIViewController			*_viewController;

+(CameraThread*)sharedCameraControllerInstance;

- (void)startCameraView:(UIViewController*)controller withPicker:(UIImagePickerController*)picker;

@end
