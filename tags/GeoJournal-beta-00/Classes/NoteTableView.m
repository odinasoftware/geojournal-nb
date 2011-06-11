//
//  NoteTableView.m
//  GeoJournal
//
//  Created by Jae Han on 7/13/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "NoteTableView.h"
#import "GeoJournalHeaders.h"

@implementation NoteTableView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}

#pragma mark SCROLL EVENT
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	TRACE("%s\n", __func__);
}

- (void)scrollViewDidScroll:(UIScrollView *)sender 
{
	TRACE_HERE;
}

#pragma mark TOUCHES EVENTS
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	TRACE("%s\n", __func__);
}



- (void)dealloc {
    [super dealloc];
}


@end
