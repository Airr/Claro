/* Claro Graphics - an abstraction layer for native UI libraries
 * 
 * $Id$
 * 
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * See the LICENSE file for more details.
 */


#define _PLATFORM_INC
#include "graphics.h"
#include "platform/macosx_cocoa.h"

/* Textarea */

//int cgraphics_unikeycode_to_claro( int code )
//{
//	return code;
//}

/* ClaroTextArea (subclassed from NSTextView) */
@interface ClaroTextArea : NSTextView
{
	widget_t *cw;
}

/* internal init function */
- (void)setClaroWidget:(widget_t *)widget;

/* notification responders */
- (void)claroResize:(NSNotification *)aNotification;
- (void)claroMove:(NSNotification *)aNotification;
- (void)claroClose:(NSNotification *)aNotification;
- (void)claroTextChanged:(NSNotification *)aNotification;

/* event responders */
//- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
@end

@implementation ClaroTextArea

//- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
//{
//	NSString *chars;
//	int code;
//	
//	if ( !( cw->notify_flags & cNotifyKey ) )
//		return 0;
//	
//	chars = [theEvent charactersIgnoringModifiers];
//	
//	/* FIXME: this is crap. maybe we could handle keyDown/Up
//			  in the window and manually find the focused widget? */
//	code = cgraphics_unikeycode_to_claro( [chars characterAtIndex:0] );
//	event_send( OBJECT(cw), "key_down", "i", code );
//	
//	return YES;
//}

- (void)claroResize:(NSNotification *)aNotification
{
	NSRect frame = [self frame];
	widget_set_size( (object_t *)cw, frame.size.width, frame.size.height, 1 );
}

- (void)claroMove:(NSNotification *)aNotification
{
	NSRect frame = [self frame];
	widget_set_position( (object_t *)cw, frame.origin.x, frame.origin.y, 1 );
}

- (void)claroClose:(NSNotification *)aNotification
{
	widget_destroy( (object_t *)cw );
}

- (void)claroTextChanged:(NSNotification *)aNotification
{
	NSString *s = [self string];
	textarea_widget_t *ta = (textarea_widget_t *)cw;
	
	strcpy( ta->text, [s UTF8String] );
	
	event_send( OBJECT(cw), "changed", "" );
}

- (void)setClaroWidget:(widget_t *)widget
{
	cw = widget;
	
//	[self setTarget: self];
//	[self setDelegate: self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(claroClose:) name:NSWindowWillCloseNotification
		object:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(claroResize:) name:NSWindowDidResizeNotification
		object:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(claroMove:) name:NSWindowDidMoveNotification
		object:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(claroTextChanged:) name:NSControlTextDidChangeNotification
		object:self];
}

@end


void cgraphics_textarea_widget_create( widget_t *widget )
{
	ClaroTextArea *ta;
	NSView *parent = cgraphics_get_native_parent( widget );

	if ( widget->size_req->w < 0 )
		widget->size_req->w = 0;
	if ( widget->size_req->h == -1 )
		widget->size_req->h = 21;
	
	ta = [[ClaroTextArea alloc]
		initWithFrame: NSMakeRect( widget->size_req->x, widget->size_req->y, widget->size_req->w, widget->size_req->h )
		];
	
	
	[ta setClaroWidget:widget];
	[parent addSubview: ta];
//	[[ta textStorage] setFont:[NSFont fontWithName:@"Menlo" size:20]];
	
	widget->native = (NSControl *)ta;

}

void cgraphics_textarea_set_text( textarea_widget_t *widget )
{
  ClaroTextArea *ta = (ClaroTextArea *)widget->widget.native;
  NSString *str;

	str = [[NSString alloc] initWithCString:widget->text encoding:NSUTF8StringEncoding];
		
	[ta setString:str];
	
}

char *cgraphics_textarea_get_text( textarea_widget_t *widget )
{
	ClaroTextArea *ta = (ClaroTextArea *)widget->widget.native;
	const char* str = [[ta string] UTF8String];
	if (strlen(str)>0) {
	  return strdup(str);
	}else{
	  return "";
	}
	
	
}
