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

NSString *const kRegexYohoEmotion = @"kRegexYohoEmotion";



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
    //注意要使用存取器
    self.text = @"";
    self.font = [UIFont systemFontOfSize:17.0f];
    [self setBackgroundColor:[UIColor clearColor]];
    self.markColor = [UIColor blueColor];
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

- (void)setText:(NSString *)text
{
    _text = [text copy];
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
        /**
         *  无论有没有emoji,行高是一样的。行高的计算是从左下角为坐标系统原点，绘制时文字是反向的，所以ascender在下面，而descender在上面。第0个起始点应该是
         *  bounds.size.height-ascender;
         */
//        lineOrigin.y = rect.size.height-self.font.ascender - self.font.lineHeight*i;
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
                imageDrawRect.size = CGSizeMake(20, 20);
                imageDrawRect.origin.x = runRect.origin.x + lineOrigin.x;
                imageDrawRect.origin.y = lineOrigin.y-5;
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
    
    NSAttributedString *attributeString = [self parserTextForDraw];//[[NSAttributedString alloc] initWithString:_text attributes:_attributes];
    
    if (_ctFrameSetter) {
        CFRelease(_ctFrameSetter);
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
    }
    _ctFrame = CTFramesetterCreateFrame(_ctFrameSetter, CFRangeMake(0, 0), [path CGPath], NULL);
}

- (NSAttributedString *)parserTextForDraw
{
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:_text attributes:_attributes];
    NSString *yohoEmotionPattern = self.regexDict[kRegexYohoEmotion];
    if (!yohoEmotionPattern || yohoEmotionPattern.length == 0) {
        return attributeString;
    }
    NSError *error = nil;
    //通过正则表达式匹配字符串
    NSRegularExpression *yohoEmotionRegular = [NSRegularExpression regularExpressionWithPattern:yohoEmotionPattern options:NSRegularExpressionDotMatchesLineSeparators error:&error];
    NSArray *checkingResults = [yohoEmotionRegular matchesInString:attributeString.string options:NSMatchingReportCompletion range:NSMakeRange(0,attributeString.length)];
    //倒着替换，这样就不会使一次替换后range发生变化
    for (int row = checkingResults.count-1;row>=0;row--) {
        NSTextCheckingResult *checkingResult = checkingResults[row];
        NSString *checkingStr = [attributeString.string substringWithRange:checkingResult.range];
        checkingStr = [checkingStr substringWithRange:NSMakeRange(1, 2)];
        BOOL shouldDrawEmotion = [self.delegate containerView:self shouldDrawEmotionWithTag:checkingStr];
        if (shouldDrawEmotion) {
            CTRunDelegateRef runDelegate = [self runDelegateForImage:(__bridge void *)(checkingStr)];
            //逻辑定义要求占位字符串长度与替换前字符串长度一致
            NSMutableAttributedString *placeHolderAttributeStr = [[NSMutableAttributedString alloc] initWithString:@"...." attributes:@{@"YHECustomEmotion": checkingStr}];
            [placeHolderAttributeStr addAttribute:(__bridge NSString *)kCTRunDelegateAttributeName value:(id)CFBridgingRelease(runDelegate) range:NSMakeRange(0, placeHolderAttributeStr.length)];
            [attributeString replaceCharactersInRange:checkingResult.range withAttributedString:placeHolderAttributeStr];
        }
    }
    
    CTParagraphStyleRef paragraphStyle = [self parserTextParagraphStyle];
    [attributeString addAttribute:(__bridge NSString *)kCTParagraphStyleAttributeName value:(__bridge id)paragraphStyle range:NSMakeRange(0, attributeString.length)];
    
    return attributeString;
}

- (CTParagraphStyleRef)parserTextParagraphStyle
{
    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
    CTTextAlignment textAlignment = kCTTextAlignmentLeft;
    CGFloat headLineIdent = 3.0;
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
    
    CTParagraphStyleRef styleRef = CTParagraphStyleCreate(styleSetting, sizeof(styleSetting));
    return styleRef;
}

#pragma mark -

#pragma mark - 绘制界面文本选中,光标等几何计算
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
    index = MIN(self.text.length, index);
    // 如果没有文本的特殊情交
    if (self.text.length == 0) {
        CGPoint origin = CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) - self.font.leading);
		// Note: using fabs() for typically negative descender from fonts.
        
        return CGRectMake(origin.x, origin.y - fabs(self.font.descender), CGRectGetWidth(self.caretView.bounds), self.font.ascender + fabs(self.font.descender));
    }
    
	// Iterate over our CTLines, looking for the line that encompasses the given range.
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    CFIndex linesCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[linesCount];
    CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    // 特殊情况，插入点正好在最后并要开始新的一行
    if (index == self.text.length && [self.text characterAtIndex:(index - 1)] == '\n') {
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, linesCount -1);
        CFRange range = CTLineGetStringRange(line);

        CGPoint lineOrigin = lineOrigins[linesCount-1];
        CGFloat ascent, descent;
        CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        CTFrameGetLineOrigins(_ctFrame, CFRangeMake(linesCount - 1, 0), &lineOrigin);
        
        CGFloat xPos = CTLineGetOffsetForStringIndex(line, range.location, NULL);
        return CGRectMake(xPos, lineOrigin.y - descent, 3, ascent + descent);
    }
    
    // 正常情况，插入点在文本中间
    // 如果选中位置的前一个字符串是回车符，计算加1的位置
    if (index>0 && [self.text characterAtIndex:(index - 1)] == '\n') {
        index += 1;
    }
    
    for (CFIndex linesIndex = 0; linesIndex < linesCount; linesIndex++) {
        
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, linesIndex);
        CFRange range = CTLineGetStringRange(line);
//        NSInteger localIndex = index - range.location;
        //计算索引是不是在本行
        if (index >= range.location && index < range.location + range.length) {
            
            CGPoint lineOrigin = lineOrigins[linesIndex];
            
            CGFloat ascent= 0.0f, descent = 0.0f;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            
			// index is in the range for this line.
            CGFloat xPos = CTLineGetOffsetForStringIndex(line, index, NULL);

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
            return CTLineGetStringIndexForPosition(line, point);
        }
    }
    
    return  self.text.length;
}

- (NSInteger)closestIndexForRichTextFromPoint:(CGPoint)point
{
    NSInteger index = [self closestIndexToPoint:point];
    NSString *yohoEmotionPattern = self.regexDict[kRegexYohoEmotion];
    if (yohoEmotionPattern) {
        NSError *error = nil;
        //通过正则表达式匹配字符串
        NSRegularExpression *yohoEmotionRegular = [NSRegularExpression regularExpressionWithPattern:yohoEmotionPattern options:NSRegularExpressionDotMatchesLineSeparators error:&error];
        NSArray *checkingResults = [yohoEmotionRegular matchesInString:_text options:NSMatchingReportCompletion range:NSMakeRange(0,_text.length)];
        for (NSTextCheckingResult *textCheckingResult in checkingResults) {
            if ((index>textCheckingResult.range.location)&&(index<textCheckingResult.range.location+textCheckingResult.range.length)) {
                index = textCheckingResult.range.location + textCheckingResult.range.length;
            }
        }
    }
    return index;
}

#pragma mark - CTRunDelegateCallBack
#pragma mark - 绘制自定义表情的几何回调
- (CTRunDelegateRef)runDelegateForImage:(void *)refCon
{
    CTRunDelegateCallbacks imageCallBacks;
    imageCallBacks.dealloc = RunDelegateDeallocCallBack;
    imageCallBacks.version = kCTRunDelegateVersion1;
    imageCallBacks.getAscent = RunDelegateGetAscentCallback;
    imageCallBacks.getDescent = RunDelegateGetDescentCallback;
    imageCallBacks.getWidth = RunDelegateGetWidthCallback;
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&imageCallBacks,refCon);
    return runDelegate;
}

void RunDelegateDeallocCallBack(void *refCon)
{
    
}

CGFloat RunDelegateGetAscentCallback(void *refCon)
{
    return 13.7f;
}

CGFloat RunDelegateGetDescentCallback(void *refCon)
{
    return 3.3f;
}

CGFloat RunDelegateGetWidthCallback(void *refCon)
{
    return 5.0f;
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
