//
//  YHETextContainerView.m
//  CoreTextDemo
//
//  Created by Christ on 14-8-18.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import "YHETextContainerView.h"
#import "YHECaretView.h"

#pragma mark - YHETextContainerView



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

- (void)dealloc
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

- (void)initView
{
    self.layer.geometryFlipped = YES;
    //注意要使用存取器
    self.attrText = [[NSMutableAttributedString alloc] init];
    self.font = [UIFont systemFontOfSize:17.0f];
    [self setBackgroundColor:[UIColor clearColor]];
    self.markColor = [UIColor colorWithRed:19.0/255.0 green:84.0/255.0 blue:214.0/255.0 alpha:1.0];
    self.attributes = [[NSMutableDictionary alloc] init];
    [self.attributes setObject:_font forKey:NSFontAttributeName];
    _caretView = [[YHECaretView alloc] initWithFrame:CGRectZero];
    _regexDict = [[NSMutableDictionary alloc] init];
    
}

#pragma mark - 属性存取器重写

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (_ctFrame != NULL) {
        [self updateCTFrame];
    }
    [self.delegate containerViewDidChangeFrame:self];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    if (_ctFrame != NULL) {
        [self updateCTFrame];
    }
    [self.delegate containerViewDidChangeFrame:self];
}

- (void)setAttrText:(NSMutableAttributedString *)attrText
{
    _attrText = attrText;
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

- (void)setSelectedTextRange:(NSRange)selectedRange
{
    _selectedTextRange = selectedRange;
    [self selectionChanged];
}


- (void)setEditing:(BOOL)editing
{
    _editing = editing;
    [self selectionChanged];
}

#pragma mark - 文本绘制区域

- (void)drawRect:(CGRect)rect
{
    [self drawRangeAsSelectedOrMarkedRange:_markedTextRange withRect:rect];
    [self drawRangeAsSelectedOrMarkedRange:_selectedTextRange withRect:rect];
    [self drawTextInRect:rect];
}

//绘制当前正在编辑文本的会话或绘制选择的文本区域
- (void)drawRangeAsSelectedOrMarkedRange:(NSRange)range withRect:(CGRect)rect
{
    if (!self.editing) {return;}
    
    if ( range.length == 0 || range.location == NSNotFound) { return; }
    
    [self.markColor setFill];
    
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    int lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), lineOrigins);
    for (int i = 0; i< CFArrayGetCount(lines); i++) {
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, i);
        CFRange lineRange = CTLineGetStringRange(line);
        NSRange interSection = [YHETextContainerView RangeIntersection:NSMakeRange(lineRange.location, lineRange.length) WithSecond:range];
        
        if (interSection.location != NSNotFound && interSection.length >0) {
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, interSection.location, NULL);
            CGFloat xEnd = CTLineGetOffsetForStringIndex(line, interSection.location + interSection.length, NULL);
            CGPoint lineOrigin = lineOrigins[i];
            CGFloat ascent,descent;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            CGRect markedRect = CGRectMake(xStart, lineOrigin.y-descent, xEnd-xStart, ascent + descent);
            UIRectFill(markedRect);
        }
    }
}

//绘制界面上的文本
- (void)drawTextInRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CTFrameRef ctFrame = _ctFrame;
    
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    NSInteger linesCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[linesCount];
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    for (int i = 0; i < CFArrayGetCount(lines); i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGPoint lineOrigin =lineOrigins[i];
        CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
        CTLineDraw(line, context);
        [self drawEmotionsWithContext:context ForLine:line withLineOrigin:lineOrigin];
    }
}

- (void)drawEmotionsWithContext:(CGContextRef)context ForLine:(CTLineRef)line withLineOrigin:(CGPoint)lineOrigin
{
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    for (int j = 0; j < CFArrayGetCount(runs); j++) {
        CGFloat runAscent;
        CGFloat runDescent;
        CGFloat runLeading;
        CTRunRef run = CFArrayGetValueAtIndex(runs, j);
        NSDictionary* attributes = (NSDictionary*)CTRunGetAttributes(run);
        CGRect runRect;
        runRect.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, &runLeading);
        runRect=CGRectMake(lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL), lineOrigin.y, runRect.size.width, runAscent + runDescent);
        
        NSString *imageName = [attributes objectForKey:@"YHECustomEmotion"];
        
        //图片渲染逻辑
        if (imageName) {
            UIImage *image = [self.delegate containerView:self willDrawEmotionWithTag:imageName];
            if (!image) {
                [NSException raise:@"未能获得表情图片" format:@"请确认对应的tag是否存在对应的表情图片"];
            }
            if (image) {
                CGRect imageDrawRect;
                imageDrawRect.size = image.size;
                imageDrawRect.size = CGSizeMake(16, 16);
                imageDrawRect.origin.x = runRect.origin.x + lineOrigin.x;
                imageDrawRect.origin.y = lineOrigin.y-3;
                CGContextDrawImage(context, imageDrawRect, image.CGImage);
            }
        }
    }
}

#pragma mark - 区域计算
+ (NSRange)RangeIntersection:(NSRange)first WithSecond:(NSRange)second
{
    NSRange result = NSMakeRange(NSNotFound, 0);
    //总共应该有5种情况,因为关于中心对称，所以可以更换两个位置取交集
    if (first.location>second.location) {
        NSRange tmp = first;
        first = second;
        second = tmp;
    }
    //交换之后始终second.location在first.location的后面
    if (second.location < first.location + first.length) {
        result.location = second.location;
        NSUInteger end = MIN(first.location+first.length, second.location + second.length);
        result.length = end-result.location;
    }
    
    return result;
}

+ (NSRange)RangeEncapsulateWithIntersection:(NSRange)first WithSecond:(NSRange)second
{
    NSRange result = [YHETextContainerView RangeIntersection:first WithSecond:second];
    if (result.location != NSNotFound) {
        result.location = MIN(first.location, second.location);
        NSInteger end = MAX(first.location+first.length, second.location + second.length);
        result.length = end - result.location;
    }
    return result;
}


#pragma mark - 文本预处理
- (void)textChanged
{
    //重新计算本视图的高度
    
    [self setNeedsDisplay];
    [self clearPreviousLayoutInfomation];

    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:_attrText];
    [attributeString addAttributes:_attributes range:NSMakeRange(0, _attrText.length)];
    CTParagraphStyleRef paragraphStyle = [self parserTextParagraphStyle];
    [attributeString addAttribute:(__bridge NSString *)kCTParagraphStyleAttributeName value:(__bridge id)paragraphStyle range:NSMakeRange(0, attributeString.length)];
    CFRelease(paragraphStyle);
    if (_ctFrameSetter) {
        CFRelease(_ctFrameSetter);
        _ctFrameSetter = NULL;
    }

    _ctFrameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributeString);
    CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(_ctFrameSetter, CFRangeMake(0, 0), NULL, CGSizeMake(self.frame.size.width, CGFLOAT_MAX), NULL);
    [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, ceilf(size.height)+17.0f)];
    
    [self updateCTFrame];
}

- (void)selectionChanged
{
    if (!_editing) {
        [self.caretView removeFromSuperview];
        return;
    }
    
    
    if (self.selectedTextRange.length == 0) {
        self.caretView.frame = [self caretRectForPosition:self.selectedTextRange.location];
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
    
    if (self.selectedTextRange.length>0) {
        CGRect startGaberRect = [self caretRectForPosition:self.selectedTextRange.location];
        CGRect endGaberRect = [self caretRectForPosition:NSMaxRange(self.selectedTextRange)];
        [self.textSelectionView setStartFrame:startGaberRect endFrame:endGaberRect];
        [self.textSelectionView showGarbers];
    }
    else
    {
        [self.textSelectionView hideGarbers];
    }
}

- (void)updateCTFrame
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
    if (_ctFrame != NULL) {
        CFRelease(_ctFrame);
        _ctFrame = NULL;
    }
    _ctFrame = CTFramesetterCreateFrame(_ctFrameSetter, CFRangeMake(0, 0), [path CGPath], NULL);
}

- (CTParagraphStyleRef)parserTextParagraphStyle
{
    CTLineBreakMode lineBreakMode = kCTLineBreakByCharWrapping;
    CTTextAlignment textAlignment = kCTTextAlignmentLeft;
    CGFloat minLineHeight = 17.0;
    CGFloat maxLineHeight = 23.0;
    CGFloat minLineSpacing = 0.0;
    CGFloat maxLineSpacing = 0.0;
    
    CTParagraphStyleSetting styleSetting[] = {
        {kCTParagraphStyleSpecifierLineBreakMode,sizeof(CTLineBreakMode),(const void *)&lineBreakMode},
        {kCTParagraphStyleSpecifierAlignment,sizeof(CTTextAlignment),(const void *)&textAlignment},
        {kCTParagraphStyleSpecifierMinimumLineSpacing,sizeof(CGFloat),(const void *)&minLineSpacing},
        {kCTParagraphStyleSpecifierMaximumLineSpacing,sizeof(CGFloat),(const void *)&maxLineSpacing},
        {kCTParagraphStyleSpecifierMinimumLineHeight,sizeof(CGFloat),(const void *)&minLineHeight},
        {kCTParagraphStyleSpecifierMaximumLineHeight,sizeof(CGFloat),(const void *)&maxLineHeight}
    };
    
    CTParagraphStyleRef styleRef = CTParagraphStyleCreate(styleSetting, 6);
    return styleRef;
}

#pragma mark -

#pragma mark - 绘制界面文本选中,光标等几何计算
- (CGRect)firstRectForRange:(NSRange)range
{
   /* NSInteger index = range.location;
    
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    NSInteger linesCount = CFArrayGetCount(lines);
    
    CGPoint origin;

    
    for (CFIndex lineIndex=0 ; lineIndex < linesCount ; lineIndex++) {
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, lineIndex);
        CFRange lineRange = CTLineGetStringRange(line);
        NSInteger localIndex = index - lineRange.location;
        if (localIndex >=0 && localIndex < lineRange.length) {
            NSInteger finalIndex = MIN(lineRange.location+lineRange.length, range.location + range.length);
            
            CFRange range = CFRangeMake(0, 0);
            range.location = lineIndex;

            CTFrameGetLineOrigins(_ctFrame, range, &origin);
            
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, index, NULL);
            CGFloat xEnd = CTLineGetOffsetForStringIndex(line, finalIndex, NULL);
            
            return CGRectMake(xStart, origin.y - descent, xEnd-xStart, ascent + descent);
        }
    }
    
    return CGRectNull;*/
    
    NSInteger index = range.location;
    
	// Iterate over the CTLines, looking for the line that encompasses the given range.
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    NSInteger linesCount = CFArrayGetCount(lines);
    
    for (CFIndex linesIndex = 0; linesIndex < linesCount; linesIndex++) {
        
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, linesIndex);
        CFRange lineRange = CTLineGetStringRange(line);
        NSInteger localIndex = index - lineRange.location;
        
        if (localIndex >= 0 && localIndex < lineRange.length) {
			// For this sample, we use just the first line that intersects range.
            NSInteger finalIndex = MIN(lineRange.location + lineRange.length, range.location + range.length);
			// Create a rect for the given range within this line.
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, index, NULL);
            CGFloat xEnd = CTLineGetOffsetForStringIndex(line, finalIndex, NULL);

            CGFloat ascent, descent;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            
            CGPoint origin;
            CTFrameGetLineOrigins(_ctFrame, CFRangeMake(linesIndex, 0), &origin);
            return CGRectMake(xStart, origin.y - descent, xEnd - xStart, ascent + descent);
        }
    }
    
    return CGRectNull;
}

- (CGRect)caretRectForPosition:(int )index
{
    index = MIN(self.attrText.length, index);
    // 如果没有文本的特殊情交
    if (self.attrText.length == 0) {
        CGPoint origin = CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) - self.font.leading);
		// Note: using fabs() for typically negative descender from fonts.
        
        return CGRectMake(origin.x, origin.y - fabs(self.font.descender), CGRectGetWidth(self.caretView.bounds), self.font.ascender + fabs(self.font.descender));
    }
    
	// Iterate over our CTLines, looking for the line that encompasses the given range.
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    CFIndex linesCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[linesCount];
    CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    for (CFIndex linesIndex = 0; linesIndex < linesCount; linesIndex++) {
        
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, linesIndex);
        CFRange range = CTLineGetStringRange(line);
        //计算索引是不是在本行
        if (index >= range.location && index <= range.location + range.length) {
            
            CGPoint lineOrigin = lineOrigins[linesIndex];
            
            CGFloat ascent= 0.0f, descent = 0.0f;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            
			// index is in the range for this line.
            CGFloat xPos = CTLineGetOffsetForStringIndex(line, index, NULL);
            
            //如果刚好前面是一个换行符，那么应该置光标于下一行的行首
            if ([self.attrText.string characterAtIndex:(index - 1)] == '\n'){
                // Place point after last line, including any font leading spacing if applicable.
                xPos = lineOrigin.x;
                lineOrigin.y -= self.font.leading;
            }

			// Make a small "caret" rect at the index position.
            return CGRectMake(xPos, lineOrigin.y - descent, 3, ascent + descent);
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
    CGPoint lineOrigins[linesCount];
    
    CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, linesCount), lineOrigins);
    
    for (CFIndex linesIndex = 0; linesIndex < linesCount; linesIndex++) {
        CGPoint lineOrigin = lineOrigins[linesIndex];
        if (point.y > lineOrigin.y) {
			// This line origin is closest to the y-coordinate of our point; now look for the closest string index in this line.
            
            CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, linesIndex);
            NSInteger stringIndex = CTLineGetStringIndexForPosition(line, point);
            //如果计算出来的光标位置前面一个刚好的换行符，要向前移一格
            if ([self.attrText.string characterAtIndex:stringIndex-1] == '\n')
            {
                stringIndex -=1;
            }
            return stringIndex;
        }
    }
    
    return  self.attrText.length;
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
