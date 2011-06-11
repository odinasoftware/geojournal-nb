//
//  GeoTakeController.h
//  GeoJournal
//
//  Created by Jae Han on 5/27/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import <MapKit/MKReverseGeocoder.h>

typedef enum {GEO_MAP, GEO_NOTE, GEO_CAMERA, GEO_RECORD} GeoCurrentStatusType; 
typedef enum {JOURNAL_NONE, JOURNAL_TAKEN, JOURNAL_CANCELLED} JournalTakenStatusType;
	
@class SpeakHereController;
@class AQLevelMeter;
@class CameraController;
@class TextInputController;

@interface GeoTakeController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, MKReverseGeocoderDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
	@private
	// IBOutlets
	// Top Tab buttons
	IBOutlet UIButton		*mapButton;
	IBOutlet UIButton		*pictureButton;
	IBOutlet UIButton		*noteButton;
	IBOutlet UIButton		*voiceButton;
	
	IBOutlet UIToolbar		*toolBar;
	
	// views
	IBOutlet UIView			*insideView;
	IBOutlet UIView			*audioView;
	IBOutlet UITextView		*textView;
	//IBOutlet AQLevelMeter	*lvlMeter_in;
	IBOutlet UIImageView	*textBackground;
	
	IBOutlet SpeakHereController *audioController;

	IBOutlet MKMapView		*mapView;
	
	// For map
	MKReverseGeocoder		*geoCoder;
	CLLocationManager		*locationManager;
	//CLLocationCoordinate2D	location;
	CLLocation				*location;
	
	// For picture
	UIImageView				*pictureView;
	UIImageView				*backgroundImage;
	UIImage					*pictureTakenImage;
	UIImage					*thumbnailImage;
	
	// Images for tab button.
	UIImage					*onImage;
	UIImage					*offImage;
	UIImage					*locateImage;
	
	// For camera view
	UIImagePickerController	*cameraController;
	
	
	BOOL					bButtonMapOn;
	BOOL					bButtonPictureOn;
	BOOL					bButtonNoteOn;
	
	GeoCurrentStatusType	geoCurrentStatus;
	
	// File names for journal
	NSString				*myAudio;
	NSString				*myPicture;
	NSString				*myTitle;
	NSString				*myNote;
	NSString				*myLocation;
	
	NSInteger				selectedCategory;
	BOOL					keyboardShown;
	JournalTakenStatusType	journalTaken;
	NSString				*titleForJournal;
}

@property (nonatomic, retain) UIImageView	*backgroundImage;
@property (nonatomic, retain) NSString		*titleForJournal;
@property (nonatomic, retain) UIButton		*mapButton;
@property (nonatomic, retain) UIButton		*pictureButton;
@property (nonatomic, retain) UIButton		*noteButton;
@property (nonatomic, retain) UIButton		*voiceButton;
@property (nonatomic, retain) UIToolbar		*toolBar;
@property (nonatomic, retain) UIView		*insideView;
@property (nonatomic, retain) UIView		*audioView;
@property (nonatomic, retain) UITextView	*textView;
@property (nonatomic, retain) UIImageView	*pictureView;
@property (nonatomic, retain) MKMapView		*mapView;
@property (nonatomic, retain) UIImage		*pictureTakenImage;
@property (nonatomic, retain) UIImage		*thumbnailImage;
@property (nonatomic, retain) UIImageView	*textBackground;

// toolbar images
@property (nonatomic, retain) UIImage		*onImage;
@property (nonatomic, retain) UIImage		*offImage;
@property (nonatomic, retain) UIImage		*locateImage;

// controllers
@property (nonatomic, retain) MKReverseGeocoder	*geoCoder;
@property (nonatomic, retain) CLLocationManager	*locationManager;
@property (nonatomic, retain) UIImagePickerController	*cameraController;
@property (nonatomic, retain) CLLocation	*location;

// For file management
@property (nonatomic, retain) NSString		*myAudio;
@property (nonatomic, retain) NSString		*myPicture;
@property (nonatomic, retain) NSString		*myNote;
@property (nonatomic, retain) NSString		*myLocation;
@property (nonatomic, retain) NSString		*myTitle;

@property (nonatomic) NSInteger				selectedCategory;
@property (nonatomic) JournalTakenStatusType	journalTaken;

@property (nonatomic, retain) SpeakHereController *audioController;

- (IBAction)toggleButtonMap:(id)sender;
- (IBAction)toggleButtonPicture:(id)sender;
- (IBAction)toggleButtonNote:(id)sender;
- (IBAction)toggleButtonVoice:(id)sender;

- (void)locateUser:(id)sender;

- (void)startView:(GeoCurrentStatusType)mode;
- (void)startAudioView;
- (void)closeAudioPlayer;
- (void)startMapView ;
- (void)startNoteView;
- (void)startCameraView;
- (void)removeSubviews;

- (void)retake:(id)sender;
- (void)cancelAction:(id)sender;
- (void)doneAction:(id)sender;

- (void)cleanView:(GeoCurrentStatusType)mode;
- (void)cleanRecordView;
- (void)saveToDatabase;

- (void)registerForKeyboardNotifications;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWasHidden:(NSNotification*)aNotification;

@end
