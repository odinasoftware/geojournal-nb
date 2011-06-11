/*
 * GeoJournalHeaders.h
 *  common header definitions
 */
#ifdef _DEBUG
#define TRACE(fmt, args...) printf(fmt, ## args)
#else
#define TRACE(fmt, args...)
#endif

#define	TRACE_HERE		TRACE("%s\n", __func__)

#define DEBUG_RECT(string, rect) \
	TRACE("%s rect: x: %f, y: %f, w: %f, h: %f\n", string, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)

#define DEBUG_SIZE(string, size) \
TRACE("%s size: w: %f, h: %f\n", string, size.width, size.height)

#define DEBUG_POINT(string, origin) \
TRACE("%s point: x: %f, y: %f\n", string, origin.x, origin.y)


#define CENTER_RECT(frame, viewframe)	\
	CGRectMake(viewframe.size.width/2-frame.size.width/2, viewframe.size.height/2-frame.size.height/2, frame.size.width, frame.size.height)

#define GORECORDING_STARTED						@"Recording started."
#define GORECORDING_STARTED_ALREADY				@"Recording started already."
#define GORECORDING_PASUED						@"Recording paused."
#define GORECORDING_PASUED_ALREADY				@"Recording paused already."
#define GORECORDING_STOPPED						@"Recording stopped."
#define GORECORDING_STOPPED_ALREADY				@"Recording stopped already."
#define GOAUDIO_PLAY_STARTED					@"Audio play started."
#define GOAUDIO_PLAY_PASUED						@"Audio play paused."
#define GOAUDIO_PLAY_STOPPED					@"Audio play stopped."

#define GORECORDING_NOTHING_TO_PLAY				@"There is nothing to play."
#define GORECORDING_NOTHING_TO_PAUSE			@"There is nothing to pause."
#define GORECORDING_NOTHING_TO_STOP				@"There is nothing to stop."
#define GORECORDING_RESUMED						@"Recording is resumed."
#define GOAUDIO_PLAY_STARTED_ALREADY			@"Audio is playing already."
#define GOAUDIO_PLAY_PAUSED_ALREADY				@"Audio is paused already."
#define GOAUDIO_PLAY_RESUMED					@"Audio play is resumed."

#define ADD_CATEGORY_TEXT						@"Add Category..."
#define GEO_AUDIO_NOT_AVAILABLE					@"Audio is not available."
#define ADD_MAIL_RECIPIENT						@"Add Mail Recipients..."

// Common definitions
#define GEO_IMAGE_EXT							@".png"
#define GEO_SMALL_EXT							@"_small"
#define GEO_AUDIO_EXT							@".aif"
#define MREADER_BACKGROUND_TAG					5
#define MREADER_TITLE_TAG						1
#define MREADER_IMG_TAG							2
#define MREADER_LOGO_TAG						3
#define MREADER_DESCRIPTION_TAG					4
#define MREADER_PICASA_TAG						5
#define MREADER_UPLOAD_SELECTED_TAG				6
#define MREADER_UPLOAD_NOSELECTED_TAG			7
#define NO_IMAGE_AVAIABLE						@"none"
#define DEFAULT_IMAGE							@"default"

#define TABLE_WIDTH								320
#define TABLE_HEIGHT							347

#define ICON_RECT_X								10.0
#define ICON_RECT_Y								30.0
#define ICON_RECT_WIDTH							20.0 
#define ICON_RECT_HEIGHT						20.0 

#define BACK_RECT_X								5.0
#define BACK_RECT_Y								5.0
#define BACK_RECT_WIDTH							ICON_RECT_WIDTH+5.0
#define BACK_RECT_HEIGHT						ICON_RECT_HEIGHT+5.0

#define TITLE_RECT_X							BACK_RECT_WIDTH + 10.0
#define TITLE_RECT_Y							5.0
#define TITLE_RECT_WIDTH						180	
#define TITLE_RECT_HEIGHT						20

#define DESC_RECT_X								BACK_RECT_WIDTH + 10.0
#define DESC_RECT_Y								TITLE_RECT_HEIGHT + 5.0 
#define DESC_RECT_WIDTH							TITLE_RECT_WIDTH + 20
#define DESC_RECT_HEIGHT						47

#define IMG_RECT_X								DESC_RECT_WIDTH+40.0
#define IMG_RECT_Y								20.0
#define IMG_RECT_WIDTH							60.0 //80.0 //100
#define IMG_RECT_HEIGHT							49.2 //62.0 //82.0

#define BACK_LABEL_RECT_X						ICON_RECT_X+ICON_RECT_WIDTH+5.0
#define BACK_LABEL_RECT_Y						DESC_RECT_Y+DESC_RECT_HEIGHT
#define BACK_LABEL_RECT_WIDTH					180.0
#define BACK_LABEL_RECT_HEIGHT					15.0

#define TIME_LABEL_X							BACK_LABEL_RECT_X+3.0
#define TIME_LABEL_Y							BACK_LABEL_RECT_Y
#define TIME_LABEL_WIDTH						BACK_LABEL_RECT_WIDTH-20.0
#define TIME_LABEL_HEIGHT						BACK_LABEL_RECT_HEIGHT-1.0

#define CATEGORY_DEFAULT_TYPE					0
#define CATEGORY_ENTIRE_TYPE					1

#define INFO_BUTTON_WIDTH						40
#define INFO_BUTTON_HEIGHT						40

#define DEFAULT_FONT_SIZE						16
#define MAX_FONT_SIZE							24
#define FONT_TO_HEIGHT							1.25

#define REDUCE_RATIO							3.0
#define THUMBNAIL_RATIO							15.0

#define GET_Y_IN_PROPORTION(x, image)			\
	x * (image.size.height/image.size.width)
#define GET_X_IN_PROPORTION(x, image)			\
	x * (image.size.height/image.size.width)

#define LANDSCAPE_IMAGE(x)						(x.size.width > x.size.height)

#define GET_COORD_IN_VERTICAL_PROPORTION(size, image, atX, atY)	\
	*atX = GET_X_IN_PROPORTION(size.height, image); \
	*atY = size.height;


#define MAKE_CENTER(margin)						(fabs(margin) > 0.0 ? fabs(margin)/2.0:0.0) 

#define IMAGE_ORIENTATION_LANDSCAPE(x)			\
	(x == UIImageOrientationLeft || \
	x == UIImageOrientationRight || \
	x == UIImageOrientationLeftMirrored || \
	x == UIImageOrientationRightMirrored)

#define IMAGE_ORIENTATION_PORTRAIT(x)			\
	(x == UIImageOrientationUp || \
	x == UIImageOrientationDown || \
	x == UIImageOrientationUpMirrored || \
	x == UIImageOrientationDownMirrored)

#define GET_DISTANCE(a, b)						\
	sqrt(pow(a.x-b.x, 2.0) + pow(a.y-b.y, 2.0))

typedef enum {PRESS_NONE, PRESS_BEGIN, PRESS_CANCEL, PRESS_DRAG, PRESS_END} PRESS_STATUS;

typedef struct image_holder {
	UIImageView		*imageView;
	NSString		*file_name;
	UIActivityIndicatorView	*activityView;
} image_holder;

extern void GET_COORD_IN_PROPORTION(CGSize size, UIImage *image, float *atX, float *atY);
extern NSString *getOrigFilename(NSString *filename);
		