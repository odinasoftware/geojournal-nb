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
#define GEO_IMAGE_EXT							@".jpg"
#define GEO_AUDIO_EXT							@".aif"
#define MREADER_TITLE_TAG						1
#define MREADER_IMG_TAG							2
#define MREADER_LOGO_TAG						3
#define MREADER_DESCRIPTION_TAG					4
#define NO_IMAGE_AVAIABLE						@"none"
#define DEFAULT_IMAGE							@"default"

#define TABLE_WIDTH								320
#define TABLE_HEIGHT							347

#define IMG_RECT_X								5.0
#define IMG_RECT_Y								5.0
#define IMG_RECT_WIDTH							90.0 //100
#define IMG_RECT_HEIGHT							72.0 //82.0

#define TITLE_RECT_X							IMG_RECT_WIDTH + 10.0
#define TITLE_RECT_Y							0.0
#define TITLE_RECT_WIDTH						180	
#define TITLE_RECT_HEIGHT						40

#define DESC_RECT_X								IMG_RECT_WIDTH + 10.0
#define DESC_RECT_Y								37
#define DESC_RECT_WIDTH							TITLE_RECT_WIDTH + 20
#define DESC_RECT_HEIGHT						47

