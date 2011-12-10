//
//  GeoPadHeaders.h
//  GeoJournal
//
//  Created by Jae Han on 11/12/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#ifndef GeoJournal_GeoPadHeaders_h
#define GeoJournal_GeoPadHeaders_h

#define HEIGHTS_FOR_IPAD_TABLE_CELL_IN_LANDSCAPE    200.0
#define HEIGHTS_FOR_IPAD_TABLE_CELL_IN_PORTRAIT     200.0

// For Images
#define PAD_IMG_PAD                                 10.0
#define PAD_IMG_RECT_X								40.0
#define PAD_IMG_RECT_Y								20.0
#define PAD_IMG_RECT_WIDTH							160.0 //80.0 //100
#define PAD_IMG_RECT_HEIGHT							124.2 //62.0 //82.0

// For Title
#define PAD_TITLE_RECT_Y							5.0
#define PAD_TITLE_RECT_WIDTH						180	
#define PAD_TITLE_RECT_HEIGHT						50

// For Description
#define PAD_DESC_RECT_Y								PAD_TITLE_RECT_HEIGHT + 5.0 
#define PAD_DESC_RECT_WIDTH							PAD_TITLE_RECT_WIDTH + 20
#define PAD_DESC_BOTTOM_MARGIN                      20.0

#define PAD_TEXT_MARGIN                             20.0
// For date label
#define PAD_DATE_RECT_Y                             PAD_IMG_RECT_Y + PAD_IMG_RECT_HEIGHT
#define PAD_DATE_RECT_WIDTH                         PAD_IMG_RECT_WIDTH
#define PAD_DATE_RECT_HEIGHT                        40

#define PAD_LOC_LABEL_TAG                           21
#define PAD_DATE_LABEL_TAG                          22
    
#define PAD_BOTTOM_MARGIN                           80
#define PAD_HEIGHT_WITHOUT_IMAGE                    50

#endif
