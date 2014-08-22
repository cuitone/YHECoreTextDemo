//
//  YHETextView.m
//  CoreTextDemo
//
//  Created by Christ on 14-8-14.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import "YHETextView.h"

#import <CoreText/CoreText.h>
#import "YHETextContainerView.h"
#import "YHETextPosition.h"
#import "YHETextRange.h"
#import "YHECaretView.h"

#import "YHETextMagnifierCaret.h"

@interface YHETextView ()
<UIGestureRecognizerDelegate,YHETextContainerViewDelegate>
{
    YHETextContainerView *_textContainerView;
    NSMutableString *_mutableText;
}

@property (nonatomic,strong) UITextInputStringTokenizer *tokenizer;

@property (nonatomic,strong) YHETextContainerView *textContainerView;

@property (nonatomic,strong) YHETextMagnifierCaret *magnifierCaret;



@property (nonatomic,strong) UITapGestureRecognizer *singleTapGesture;




@end

@implementation YHETextView

@synthesize inputDelegate = _inputDelegate;

@synthesize textContainerView = _textContainerView;

@synthesize text = _text;

@synthesize editable = _editable;

@dynamic regexDict;

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
    [self setBackgroundColor:[UIColor greenColor]];
    _textContainerView = [[YHETextContainerView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 17)];
    [_textContainerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self addSubview:_textContainerView];
    [_textContainerView setClipsToBounds:NO];
    [_textContainerView setDelegate:self];
    [_textContainerView setUserInteractionEnabled:YES];
    self.userInteractionEnabled = YES;
    
    self.magnifierCaret = [[YHETextMagnifierCaret alloc] init];

    _textContainerView.textSelectionView = [[YHETextSelectionView alloc] initWithFrame:_textContainerView.bounds textView:self];
    [_textContainerView.textSelectionView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [_textContainerView.textSelectionView setUserInteractionEnabled:YES];
    [_textContainerView addSubview:_textContainerView.textSelectionView];
    
    self.text = @"";
    _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
    _mutableText = [[NSMutableString alloc] init];
    
}


#pragma mark - FirstResponder

- (BOOL)endEditing:(BOOL)force
{
    BOOL endEditing = [super endEditing:force];
    [_textContainerView setEditing:!endEditing];
    return endEditing;
}

- (BOOL)canBecomeFirstResponder
{
    BOOL shouldBeginEditing = YES;
    if ([self.delegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        shouldBeginEditing = [self.delegate textViewShouldBeginEditing:self];
    }
    return shouldBeginEditing;
}

- (BOOL)canResignFirstResponder
{
    BOOL shouldEndEditing = YES;
    if ([self.delegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        shouldEndEditing = [self.delegate textViewShouldEndEditing:self];
    }
    return shouldEndEditing;
}

- (BOOL)resignFirstResponder
{
    if (_textContainerView.isEditing) {
        [_textContainerView setEditing:NO];
        if ([self.delegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
            [self.delegate textViewDidEndEditing:self];
        }
    }
    
    return [super resignFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    if (!self.isFirstResponder) {
        if (self.isEditable)
        {
            _textContainerView.editing = YES;
        }
    }
    return [super becomeFirstResponder];
}

#pragma makr - Gesture Recognizer

- (void)tap:(UITapGestureRecognizer *)tap
{
    [self hideEditingMenu];
    if (self.isFirstResponder) {
        [self.inputDelegate selectionWillChange:self];
        
        NSInteger index = [_textContainerView closestIndexForRichTextFromPoint:[tap locationInView:_textContainerView]];
        //点击屏幕后使markedTextRange.location＝NSNotFound,这样输入汉字的时候就不会从起始点开始了
        _textContainerView.markedTextRange = NSMakeRange(NSNotFound, 0);
        _textContainerView.selectedTextRange = NSMakeRange(index, 0);
        [_textContainerView setEditing:YES];
        [self.inputDelegate selectionDidChange:self];
    }
    else
    {
        [self becomeFirstResponder];
        _textContainerView.editing = YES;
        
        NSInteger index = [_textContainerView closestIndexForRichTextFromPoint:[tap locationInView:_textContainerView]];
        //点击屏幕后使markedTextRange.location＝NSNotFound,这样输入汉字的时候就不会从起始点开始了
        _textContainerView.markedTextRange = NSMakeRange(NSNotFound, 0);
        _textContainerView.selectedTextRange = NSMakeRange(index, 0);
        [_textContainerView setEditing:YES];
            
        if ([self.delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
            [self.delegate textViewDidBeginEditing:self];
        }
        
    }
}

- (void)grabSelectionGesture:(UIPanGestureRecognizer *)grabGesture
{
    UIPanGestureRecognizer *startGrabGesture = _textContainerView.textSelectionView.startGrabGesture;
    NSRange selectedTextRange = _textContainerView.selectedTextRange;
    
    BOOL isStartGesture = ([grabGesture isEqual:startGrabGesture]);
    
    if (grabGesture.state == UIGestureRecognizerStateBegan || grabGesture.state == UIGestureRecognizerStateChanged) {
        if (isStartGesture) {
            NSInteger index = [_textContainerView closestIndexForRichTextFromPoint:[grabGesture locationInView:_textContainerView]];
            //range的length是NSUInteger,所以要类型转换
            NSInteger length = selectedTextRange.length;
            length += selectedTextRange.location - index;
            if (length<=0) { return; }
            selectedTextRange = NSMakeRange(index, length);

            _textContainerView.selectedTextRange = selectedTextRange;
        }
        else
        {
            NSInteger index = [_textContainerView closestIndexForRichTextFromPoint:[grabGesture locationInView:_textContainerView]];
            //range的length是NSUInteger,所以要类型转换
            NSInteger length = index - selectedTextRange.location;
            if (length<=0) { return; }
            selectedTextRange.length = length;
            if (!NSEqualRanges(_textContainerView.selectedTextRange, selectedTextRange)) {

                _textContainerView.selectedTextRange = selectedTextRange;
            }
        }
        
    }
    else if(grabGesture.state == UIGestureRecognizerStateEnded || grabGesture.state == UIGestureRecognizerStateCancelled)
    {
        if (_textContainerView.isEditing && _textContainerView.selectedTextRange.length > 0) {
            [self showEditingMenu];
        }
        else
        {
            [self hideEditingMenu];
        }
    }
    
}

- (void)longPress:(UILongPressGestureRecognizer *)longPress
{
    CGPoint pressPoint = [longPress locationInView:self];
    //显示放大镜
    if (longPress.state == UIGestureRecognizerStateBegan || longPress.state == UIGestureRecognizerStateChanged) {
        [self moveMagnifierCaretToPoint:pressPoint];
    }
    //显示选择，全选，粘贴等操作选项
    else if(longPress.state == UIGestureRecognizerStateEnded)
    {
        [self hideMagnifierCaret];
        [self showEditingMenu];
    }
    
}

- (void)moveMagnifierCaretToPoint:(CGPoint)point
{
    if (!self.magnifierCaret.superview) {
        [self.magnifierCaret showInView:self.window atPoint:point];
    }
    [self.magnifierCaret moveToPoint:point];
}

- (void)hideMagnifierCaret
{
    [self.magnifierCaret hide];
}

- (void)showEditingMenu
{

    UIMenuController *menuController = [UIMenuController sharedMenuController];
    CGRect targetRect = CGRectZero;
    if (_textContainerView.selectedTextRange.length == 0) {
        targetRect = [self caretRectForPosition:[YHETextPosition positionWithIndex:_textContainerView.selectedTextRange.location]];
    }
    else
    {
        
    }
    [menuController setTargetRect:targetRect inView:self];
    [menuController setMenuVisible:YES animated:YES];
}

- (void)hideEditingMenu
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setMenuVisible:NO animated:YES];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    NSRange selectTextRange = _textContainerView.selectedTextRange;
    
    if (action == @selector(cut:) && selectTextRange.length > 0 && self.editable) {
        return YES;
    }
    if (action == @selector(copy:) && selectTextRange.length > 0) {
        return YES;
    }
    if (action == @selector(paste:) && _textContainerView.isEditing && [[UIPasteboard generalPasteboard] string]) {
        return YES;
    }
    if (action == @selector(select:) && self.text.length > 0 && selectTextRange.length == 0) {
        return YES;
    }
    if (action == @selector(selectAll:) && self.text.length > 0 && selectTextRange.length < self.text.length) {
        return YES;
    }
    
    return NO;
}
#pragma mark - MenuController Action
- (void)cut:(id)sender
{
    NSRange selectedTextRange = _textContainerView.selectedTextRange;
    if (selectedTextRange.length>0) {
        NSString *subText = [_mutableText substringWithRange:selectedTextRange];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        pasteBoard.string = subText;
        [self insertText:@""];
    }
}

- (void)copy:(id)sender
{
    NSRange selectedTextRange = _textContainerView.selectedTextRange;
    if (selectedTextRange.length>0) {
        NSString *subText = [_mutableText substringWithRange:selectedTextRange];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        pasteBoard.string = subText;
    }
}

- (void)paste:(id)sender
{
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    if (pasteBoard.string.length>0) {
        [self insertText:pasteBoard.string];
    }
}

- (void)select:(id)sender
{
    CGPoint center = _textContainerView.caretView.center;
    YHETextRange *caretRange = (YHETextRange *)[self characterRangeAtPoint:center];
    _textContainerView.selectedTextRange = caretRange.range;
}

- (void)selectAll:(id)sender
{
    _textContainerView.selectedTextRange = NSMakeRange(0, _mutableText.length);
}

#pragma mark - 属性存取器重写

- (void)setText:(NSString *)text
{
    if (_text != text) {
        _text = [text copy];
        [_mutableText replaceCharactersInRange:NSMakeRange(0, _mutableText.length) withString:_text];
        _textContainerView.text = text;
        
        NSRange markedTextRange = NSMakeRange(NSNotFound, 0);
        NSRange selectedTextRange = NSMakeRange(_text.length, 0);
        _textContainerView.selectedTextRange = selectedTextRange;
        _textContainerView.markedTextRange = markedTextRange;

        //在外部设置文本时要根据文本变更选择的location
    }
}

- (NSString *)text
{
    return _mutableText;
}

- (void)setFont:(UIFont *)font
{
    if (_font != font) {
        _font = font;
        _textContainerView.font = _font;
    }
}

- (void)setTextColor:(UIColor *)textColor
{
    if (_textColor != textColor) {
        _textColor = textColor;
        _textContainerView.textColor = _textColor;
    }
}

- (void)setSelectedRange:(NSRange)selectedRange
{
    if (!NSEqualRanges(selectedRange, _textContainerView.selectedTextRange)) {
        _textContainerView.selectedTextRange = selectedRange;
    }
}

- (NSRange)selectedRange
{
    return _textContainerView.selectedTextRange;
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
}

- (BOOL)isEditable
{
    return YES;
}

- (NSMutableDictionary *)regexDict
{
    return _textContainerView.regexDict;
}

#pragma mark - UITextInput

#pragma mark -  Methods for manipulating text

- (NSString *)textInRange:(UITextRange *)range
{
    YHETextRange *textRange = (YHETextRange *)range;
    return [_mutableText substringWithRange:textRange.range];
}


- (void)replaceRange:(UITextRange *)range withText:(NSString *)text
{
    YHETextRange *textRange = (YHETextRange *)range;
    NSRange selectedTextRange = _textContainerView.selectedTextRange;
    //如果替换文本在选择光标的前面，重新计算新的选择位置使光标保持在最后面
    if ((textRange.range.location+textRange.range.length) <= selectedTextRange.location) {
        //比如选择了三个字符，替换成1个字符，那么textRange.range.length - text.length=2,选择的起始位置向前移动了两个，
        selectedTextRange.location -= (textRange.range.length - text.length);
    } else
    {
        
    }
    
    [_mutableText replaceCharactersInRange:textRange.range withString:text];
    
    _text = [_mutableText copy];
    _textContainerView.text = _text;
    _textContainerView.selectedTextRange = selectedTextRange;
}



- (UITextRange *)selectedTextRange
{
    return [YHETextRange indexedRangeWithRange:_textContainerView.selectedTextRange];
}


- (void)setSelectedTextRange:(UITextRange *)range
{
    YHETextRange *indexedRange = (YHETextRange *)range;
    NSRange selectedTextRange = indexedRange.range;
    NSString *yohoEmotionPattern = self.regexDict[kRegexYohoEmotion];
    if (yohoEmotionPattern) {
        NSError *error = nil;
        //通过正则表达式匹配字符串
        NSRegularExpression *yohoEmotionRegular = [NSRegularExpression regularExpressionWithPattern:yohoEmotionPattern options:NSRegularExpressionDotMatchesLineSeparators error:&error];
        NSArray *checkingResults = [yohoEmotionRegular matchesInString:_text options:NSMatchingReportCompletion range:NSMakeRange(0,_text.length)];
        for (NSTextCheckingResult *textCheckingResult in checkingResults) {
            NSString *checkingStr = [self.text substringWithRange:textCheckingResult.range];
            checkingStr = [checkingStr substringWithRange:NSMakeRange(1, 2)];
            
            BOOL shouldDrawEmotion = NO;
            if ([self.delegate respondsToSelector:@selector(textView:shouldDrawEmotionWithTag:)]) {
                shouldDrawEmotion = [self.delegate textView:self shouldDrawEmotionWithTag:checkingStr];
            }
            if (!shouldDrawEmotion) {
                continue;
            }
            
            NSRange encapsulateRange = [YHETextContainerView RangeEncapsulateWithIntersection:selectedTextRange WithSecond:textCheckingResult.range];
            if (encapsulateRange.location != NSNotFound) {
                selectedTextRange = encapsulateRange;
            }
        }
    }
    _textContainerView.selectedTextRange = selectedTextRange;
    if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.delegate textViewDidChangeSelection:self];
    }
}


#pragma mark - Marked Text Range

- (UITextRange *)markedTextRange
{
    NSRange markedTextRange = _textContainerView.markedTextRange;
    if (markedTextRange.length == 0) {
        return nil;
    }
    return [YHETextRange indexedRangeWithRange:markedTextRange];
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange
{
    NSRange selectedTextRange = _textContainerView.selectedTextRange;
    NSRange markedTextRange = _textContainerView.markedTextRange;
    
    if (markedTextRange.location != NSNotFound) {
        if (!markedText) {markedText = @"";}
        
        [_mutableText replaceCharactersInRange:markedTextRange withString:markedText];
        markedTextRange.length = markedText.length;
        
    }
    
    else if(selectedTextRange.length>0)
    {
        [_mutableText replaceCharactersInRange:selectedTextRange withString:markedText];
        markedTextRange.location = selectedTextRange.location;
        markedTextRange.length = markedText.length;
    }
    else
    {
        [_mutableText insertString:markedText atIndex:selectedTextRange.location];
        markedTextRange.location = selectedTextRange.location;
        markedTextRange.length = markedText.length;
    }
    
    selectedTextRange = NSMakeRange(selectedRange.location+markedTextRange.location, selectedRange.length);
    
    _text = [_mutableText copy];
    _textContainerView.text = _text;
    _textContainerView.selectedTextRange = selectedTextRange;
    _textContainerView.markedTextRange = markedTextRange;
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.delegate textViewDidChange:self];
    }
}

- (void)unmarkText
{
    NSRange markedTextRange = _textContainerView.markedTextRange;
    if (markedTextRange.location == NSNotFound) {
        return;
    }
    markedTextRange.location = NSNotFound;
    _textContainerView.markedTextRange = markedTextRange;
    
}

#pragma mark - UITextInput  The end and beginning of the the text document

- (UITextPosition *)beginningOfDocument
{
    YHETextPosition *textPosition = [YHETextPosition positionWithIndex:0];
    return textPosition;
}

- (UITextPosition *)endOfDocument
{
    YHETextPosition *textPosition = [YHETextPosition positionWithIndex:_mutableText.length];
    return textPosition;
}

#pragma mark - UITextInput  Methods for creating ranges and positions

- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition
{
    YHETextPosition *aFromPosition = (YHETextPosition *)fromPosition;
    YHETextPosition *aToPosition = (YHETextPosition *)toPosition;
    NSRange range = NSMakeRange(MIN(aFromPosition.index, aToPosition.index), ABS(aToPosition.index-aFromPosition.index));
    
    return [YHETextRange indexedRangeWithRange:range];
    
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset
{
    YHETextPosition *aPosition = (YHETextPosition *)position;
    NSInteger end = aPosition.index + offset;
    if (end>self.text.length|| end < 0) {
        return nil;
    }
    return [YHETextPosition positionWithIndex:end];
}

//键盘上下左右按键会调用此方法调整光标的位置
- (UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    YHETextPosition *aPosition = (YHETextPosition *)position;
    
    NSInteger newPosition = aPosition.index;
    
    switch (direction) {
        case UITextLayoutDirectionRight:
            newPosition += offset;
            break;
        case UITextLayoutDirectionLeft:
            newPosition -= offset;
            break;
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionDown:
        default:
            break;
    }
    
    newPosition = MAX(newPosition, 0);
    newPosition = MIN(newPosition,_text.length);
    
    return [YHETextPosition positionWithIndex:newPosition];
}

#pragma mark - UITextInput  Simple evaluation of positions

- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other
{
    YHETextPosition *aPosition = (YHETextPosition *)position;
    YHETextPosition *aOther = (YHETextPosition *)other;
    if (aPosition.index<aOther.index) {
        return NSOrderedAscending;
    }
    else if(aPosition.index<aOther.index)
    {
        return NSOrderedDescending;
    }
    return NSOrderedAscending;
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition
{
    YHETextPosition *aFrom = (YHETextPosition *)from;
    YHETextPosition *aToPosition = (YHETextPosition *)toPosition;
    return (aToPosition.index - aFrom.index);
}

#pragma mark - UITextInput  Writing direction

#pragma mark UITextInput - Text Layout, writing direction and position related methods

- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction
{
    // Note that this sample assumes left-to-right text direction.
    YHETextRange *indexedRange = (YHETextRange *)range;
    NSInteger position;
 
    switch (direction) {
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            position = indexedRange.range.location;
            break;
        case UITextLayoutDirectionRight:
        case UITextLayoutDirectionDown:
            position = indexedRange.range.location + indexedRange.range.length;
            break;
    }
    
	// Return text position using our UITextPosition implementation.
	// Note that position is not currently checked against document range.
    return [YHETextPosition positionWithIndex:position];
}


- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
{
    // Note that this sample assumes left-to-right text direction.
    YHETextPosition *pos = (YHETextPosition *)position;
    NSRange result;
    
    switch (direction) {
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            result = NSMakeRange(pos.index - 1, 1);
            break;
        case UITextLayoutDirectionRight:
        case UITextLayoutDirectionDown:
            result = NSMakeRange(pos.index, 1);
            break;
    }
    
    // Return range using our UITextRange implementation.
	// Note that range is not currently checked against document range.
    return [YHETextRange indexedRangeWithRange:result];
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction
{
    return UITextWritingDirectionRightToLeft;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range
{
    //do nothing
}

#pragma mark - UITextInput Geometry used to provide, for example, a correction rect

- (CGRect)firstRectForRange:(UITextRange *)range
{
    YHETextRange *aRange = (YHETextRange *)range;
    CGRect rect = [_textContainerView firstRectForRange:aRange.range];
    return [self convertRect:rect fromView:_textContainerView];
    
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    YHETextPosition *aPosition = (YHETextPosition *)position;
    CGRect rect = [_textContainerView caretRectForPosition:aPosition.index];
    rect = [self convertRect:rect fromView:_textContainerView];
    return rect;
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range
{
    return nil;
}

#pragma mark - Hit testing
- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    NSInteger index = [_textContainerView closestIndexToPoint:point];
    return [YHETextPosition positionWithIndex:index];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range
{
    NSInteger index = [_textContainerView closestIndexToPoint:point];
    return [YHETextPosition positionWithIndex:index];
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    NSInteger index = [_textContainerView closestIndexForRichTextFromPoint:point];
    if (index == NSNotFound) {
        return nil;
    }
    
    NSInteger length = 1;
    
    index = MAX(0, index);
    
    index = MIN(self.text.length-1, index);
    
    YHETextRange *textRange = [YHETextRange indexedRangeWithRange:NSMakeRange(index, length)];
    
    return textRange;
}

#pragma mark UITextInput - Returning Text Styling Information

- (NSDictionary *)textStylingAtPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction
{
    // This sample assumes all text is single-styled, so this is easy.
    if (!self.font) {
        self.font = [UIFont systemFontOfSize:17.0];
    }
    return @{ UITextInputTextFontKey : self.font };
}

#pragma mark - UIKeyInput

- (BOOL)hasText
{
    return (_mutableText.length>0);
}

- (void)insertText:(NSString *)text
{
    NSRange selectedTextRange = _textContainerView.selectedTextRange;
    NSRange markedTextRange = _textContainerView.markedTextRange;
    
    if (markedTextRange.location != NSNotFound) {
        BOOL shouldChange = YES;
        if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            shouldChange = [self.delegate textView:self shouldChangeTextInRange:markedTextRange replacementText:text];
        }
        if (shouldChange) {
            [_mutableText replaceCharactersInRange:markedTextRange withString:text];
            selectedTextRange.location = markedTextRange.location+text.length;
            selectedTextRange.length = 0;
            markedTextRange = NSMakeRange(NSNotFound, 0);
        }
        else
        {
            return;
        }
    }
    else if (selectedTextRange.length > 0) {
        BOOL shouldChange = YES;
        if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            shouldChange = [self.delegate textView:self shouldChangeTextInRange:markedTextRange replacementText:text];
        }
        if (shouldChange) {
            [_mutableText replaceCharactersInRange:selectedTextRange withString:text];
            selectedTextRange = NSMakeRange(MIN(_mutableText.length, selectedTextRange.location), 0);
        }
        else
        {
            return;
        }
    }
    else
    {
        BOOL shouldChange = YES;
        if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            shouldChange = [self.delegate textView:self shouldChangeTextInRange:markedTextRange replacementText:text];
        }
        if (shouldChange) {
            [_mutableText insertString:text atIndex:selectedTextRange.location];
            selectedTextRange.location += text.length;
        }
        else
        {
            return;
        }
    }
    
    _text = [_mutableText copy];
    _textContainerView.text = _text;
    
    _textContainerView.selectedTextRange = selectedTextRange;
    _textContainerView.markedTextRange = markedTextRange;
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.delegate textViewDidChange:self];
    }
}

- (void)deleteBackward
{
    NSRange selectedTextRange = _textContainerView.selectedTextRange;
    NSRange markedTextRange = _textContainerView.markedTextRange;
    //这里如果删除到了富替换文本，那么要完整删除掉

    if (markedTextRange.location != NSNotFound) {
        BOOL shouldChange = YES;
        if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            shouldChange = [self.delegate textView:self shouldChangeTextInRange:markedTextRange replacementText:@""];
        }
        if (shouldChange) {
            [_mutableText deleteCharactersInRange:markedTextRange];
            selectedTextRange = NSMakeRange(markedTextRange.location, 0);
            markedTextRange = NSMakeRange(NSNotFound, 0);
        }
        else
        {
            return;
        }
    }
    else if (selectedTextRange.length>0) {
        BOOL shouldChange = YES;
        if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            shouldChange = [self.delegate textView:self shouldChangeTextInRange:selectedTextRange replacementText:@""];
        }
        if (shouldChange) {
            [_mutableText deleteCharactersInRange:selectedTextRange];
            selectedTextRange.length = 0;
        }
        else
        {
            return;
        }
    }
    else if(selectedTextRange.location >0)
    {
        BOOL shouldChange = YES;
        if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            shouldChange = [self.delegate textView:self shouldChangeTextInRange:selectedTextRange replacementText:@""];
        }
        if (shouldChange) {
            selectedTextRange.location --;
            selectedTextRange.length = 1;
            [_mutableText deleteCharactersInRange:selectedTextRange];
            selectedTextRange.length = 0;
        }
        else
        {
            return;
        }
    }


    _text = [_mutableText copy];
    _textContainerView.text = _text;
    _textContainerView.selectedTextRange = selectedTextRange;
    _textContainerView.markedTextRange = markedTextRange;
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.delegate textViewDidChange:self];
    }
}

#pragma mark - YHETextContainerView Delegate
- (BOOL)containerView:(YHETextContainerView *)containerView shouldDrawEmotionWithTag:(NSString *)tag
{
    if ([self.delegate respondsToSelector:@selector(textView:shouldDrawEmotionWithTag:)]) {
        return [self.delegate textView:self shouldDrawEmotionWithTag:tag];
    }
    return NO;
}

- (UIImage *)containerView:(YHETextContainerView *)containerView willDrawEmotionWithTag:(NSString *)tag
{
    if ([self.delegate respondsToSelector:@selector(textView:willDrawEmotionWithTag:)]) {
        return [self.delegate textView:self willDrawEmotionWithTag:tag];
    }
    return nil;
}

- (void)containerViewDidChangeFrame:(YHETextContainerView *)containerView
{
    CGFloat contentHeight = MAX(self.contentSize.height, _textContainerView.frame.size.height);
    if (contentHeight!=self.contentSize.height) {
        self.contentSize =  containerView.frame.size;
        CGRect caretFrame = _textContainerView.caretView.frame;
        caretFrame = [self convertRect:caretFrame fromView:_textContainerView];
        [self scrollRectToVisible:caretFrame  animated:YES];
    }
}

@end

