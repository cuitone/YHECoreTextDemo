//
//  YHETextContainerView.m
//  CoreTextDemo
//
//  Created by Christ on 14-8-18.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import "YHETextContainerView.h"
#import <CoreText/CoreText.h>
#import "YHECaretView.h"

#pragma mark - YHETextContainerView

@interface YHETextContainerView ()
{
    CTFramesetterRef _ctFrameSetter;
    CTFrameRef _ctFrame;
}

@property (nonatomic,strong) NSMutableDictionary *attributes;

@property (nonatomic,strong) YHECaretView *caretView;

@end

@implementation YHETextContainerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initView];
    }
    return self;
}

- (void)initView
{
    self.layer.geometryFlipped = YES;
    _font = [UIFont systemFontOfSize:17.0f];
    [self setBackgroundColor:[UIColor whiteColor]];
    self.attributes = [[NSMutableDictionary alloc] init];
    [self.attributes setObject:_font forKey:NSFontAttributeName];
    _caretView = [[YHECaretView alloc] initWithFrame:CGRectZero];
    
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CTFrameDraw(_ctFrame, context);
}



- (void)textChanged
{
    [self setNeedsDisplay];
    [self clearPreviousLayoutInfomation];
    
    NSAttributedString *attributeString = [[NSAttributedString alloc] initWithString:_text attributes:_attributes];
    
    if (_ctFrameSetter) {
        CFRelease(_ctFrameSetter);
    }
    _ctFrameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributeString);
    [self updateCTFrame];
}

- (void)selectionChanged
{
    if (!_editing) {
        [self.caretView removeFromSuperview];
        return;
    }
    
    if (self.selectedRange.length == 0) {
        self.caretView.frame = [self caretRectForPosition:self.selectedRange.location];
        if (self.caretView.superview == nil) {
            [self addSubview:self.caretView];
            [self setNeedsDisplay];
        }
        // Set up a timer to "blink" the caret.
        [self.caretView delayBlink];
    }
    else {
		// If there is an actual selection, don't draw the insertion caret.
        [self.caretView removeFromSuperview];
        [self setNeedsDisplay];
    }
    
    if (self.markedTextRange.location != NSNotFound) {
        [self setNeedsDisplay];
    }
}

- (void)updateCTFrame
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
    if (_ctFrame != NULL) {
        CFRelease(_ctFrame);
    }
    _ctFrame = CTFramesetterCreateFrame(_ctFrameSetter, CFRangeMake(0, 0), [path CGPath], NULL);
}

#pragma mark - 属性存取器重写

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (_ctFrame != NULL) {
        [self updateCTFrame];
    }
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    if (_ctFrame != NULL) {
        [self updateCTFrame];
    }
}

- (void)setText:(NSString *)text
{
    _text = text;
    [self textChanged];
}

- (void)setFont:(UIFont *)font
{
    if (font != _font) {
        _font = font;
        [self.attributes setObject:_font forKey:NSFontAttributeName];
        [self textChanged];
    }
}

- (void)setTextColor:(UIColor *)textColor
{
    if (_textColor != textColor) {
        _textColor = textColor;
        [self.attributes setObject:_textColor forKey:NSForegroundColorAttributeName];
        [self textChanged];
    }
}

- (void)setSelectedRange:(NSRange)selectedRange
{
    _selectedRange = selectedRange;
    [self textChanged];
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    [self selectionChanged];
}

- (void)setEditing:(BOOL)editing
{
    _editing = editing;
    [self selectionChanged];
}

#pragma mark -

#pragma mark - 
- (CGRect)firstRectForRange:(NSRange)range
{
    NSInteger index = range.location;
    
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    NSInteger linesCount = CFArrayGetCount(lines);
    
    for (int lineIndex = 0 ; lineIndex < linesCount ; lineIndex++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        CFRange lineRange = CTLineGetStringRange(line);
        NSInteger localIndex = index - lineRange.location;
        
        //找到的起始点是在这一行里
        if (localIndex>0&&localIndex < lineRange.length) {
            NSInteger finalIndex = MIN(lineRange.location+lineRange.length, range.location + range.length);
            
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, index, NULL);
            CGFloat xEnd = CTLineGetOffsetForStringIndex(line, finalIndex, NULL);
            
            CGPoint origin;
            CTFrameGetLineOrigins(_ctFrame, CFRangeMake(lineIndex, 0), &origin);
            CGFloat ascent,descent;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            return CGRectMake(xStart, origin.y - descent, xEnd-xStart, ascent + descent);
        }
    }
    
    return CGRectNull;
}

- (CGRect)caretRectForPosition:(int )index
{
    // Special case, no text.
    if (self.text.length == 0) {
        CGPoint origin = CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) - self.font.leading);
		// Note: using fabs() for typically negative descender from fonts.
        
        return CGRectMake(origin.x, origin.y - fabs(self.font.descender), 3, self.font.ascender + fabs(self.font.descender));
    }
    
	// Iterate over our CTLines, looking for the line that encompasses the given range.
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    CFIndex linesCount = CFArrayGetCount(lines);
    
    
    // Special case, insertion point at final position in text after newline.
    if (index == self.text.length && [self.text characterAtIndex:(index - 1)] == '\n') {
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, linesCount -1);
        CFRange range = CTLineGetStringRange(line);
        CGFloat xPos = CTLineGetOffsetForStringIndex(line, range.location, NULL);
        CGPoint origin;
        CGFloat ascent, descent;
        CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        CTFrameGetLineOrigins(_ctFrame, CFRangeMake(linesCount - 1, 0), &origin);
		// Place point after last line, including any font leading spacing if applicable.
        origin.y -= self.font.leading;
        
        return CGRectMake(xPos, origin.y - descent, 3, ascent + descent);
    }
    
    // Regular case, caret somewhere within our text content range.
    for (CFIndex linesIndex = 0; linesIndex < linesCount; linesIndex++) {
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, linesIndex);
        CFRange range = CTLineGetStringRange(line);
        NSInteger localIndex = index - range.location;
        if (localIndex >= 0 && localIndex <= range.length) {
			// index is in the range for this line.
            CGFloat xPos = CTLineGetOffsetForStringIndex(line, index, NULL);
            CGPoint origin;
            CGFloat ascent, descent;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            CTFrameGetLineOrigins(_ctFrame, CFRangeMake(linesIndex, 0), &origin);
            
			// Make a small "caret" rect at the index position.
            return CGRectMake(xPos, origin.y - descent, 3, ascent + descent);
        }
    }
    
    return CGRectNull;
}

// Public method to find the text range index for a given CGPoint.
- (NSInteger)closestIndexToPoint:(CGPoint)point
{
	/*
     Use Core Text to find the text index for a given CGPoint by iterating over the y-origin points for each line, finding the closest line, and finding the closest index within that line.
     */
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    CFIndex linesCount = CFArrayGetCount(lines);
    CGPoint origins[linesCount];
    
    CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, linesCount), origins);
    
    for (CFIndex linesIndex = 0; linesIndex < linesCount; linesIndex++) {
        if (point.y > origins[linesIndex].y) {
			// This line origin is closest to the y-coordinate of our point; now look for the closest string index in this line.
            CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, linesIndex);
            return CTLineGetStringIndexForPosition(line, point);
        }
    }
    
    return  self.text.length;
}

#pragma mark -

- (void)clearPreviousLayoutInfomation
{
    if (_ctFrameSetter != NULL) {
        CFRelease(_ctFrameSetter);
        _ctFrameSetter = NULL;
    }
    
    if (_ctFrame != NULL) {
        CFRelease(_ctFrame);
        _ctFrame = NULL;
    }
}

@end
