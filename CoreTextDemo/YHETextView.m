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

@interface YHETextView ()
<UIGestureRecognizerDelegate>
{
    YHETextContainerView *_textContainerView;
    NSMutableString *_mutableText;
}

@property (nonatomic,strong) UITextInputStringTokenizer *tokenizer;

@property (nonatomic,strong) YHETextContainerView *textContainerView;


@end

@implementation YHETextView

@synthesize inputDelegate = _inputDelegate;

@synthesize textContainerView = _textContainerView;

@synthesize text = _text;

@synthesize editable = _editable;

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
    _textContainerView = [[YHETextContainerView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 150)];
    [self addSubview:_textContainerView];
    [_textContainerView setUserInteractionEnabled:NO];
    self.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.delegate = self;
    [self addGestureRecognizer:tap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    longPress.numberOfTapsRequired = 1;
    longPress.numberOfTouchesRequired = 1;
    longPress.delegate = self;
    [self addGestureRecognizer:longPress];
    
    self.text = @"";
    _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
    _mutableText = [[NSMutableString alloc] init];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    return [super resignFirstResponder];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


#pragma makr - Gesture Recognizer

- (void)tap:(UITapGestureRecognizer *)tap
{
    if (self.isFirstResponder) {
        [self.inputDelegate selectionWillChange:self];
        
        NSInteger index = [_textContainerView closestIndexToPoint:[tap locationInView:_textContainerView]];
        //点击屏幕后使markedTextRange.location＝NSNotFound,这样输入汉字的时候就不会从起始点开始了
        _textContainerView.markedTextRange = NSMakeRange(NSNotFound, 0);
        _textContainerView.selectedTextRange = NSMakeRange(index, 0);
        [_textContainerView setEditing:YES];
        
        [self.inputDelegate selectionDidChange:self];
    }
    else
    {
        _textContainerView.editing = YES;
        [self becomeFirstResponder];
    }
}

- (void)longPress:(UILongPressGestureRecognizer *)longPress
{
    
}

#pragma mark - 属性存取器重写

- (void)setText:(NSString *)text
{
    if (_text != text) {
        _text = [text copy];
        [_mutableText replaceCharactersInRange:NSMakeRange(0, _mutableText.length) withString:_text];
        _textContainerView.text = text;
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

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
}

- (BOOL)isEditable
{
    return YES;
}

#pragma mark - Gesture Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return (touch.view == self);
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
    NSRange selectedRange = _textContainerView.selectedTextRange;
    //如果替换文本在选择光标的前面，重新计算新的选择位置使光标保持在最后面
    if ((textRange.range.location+textRange.range.length) <= selectedRange.location) {
        //比如选择了三个字符，替换成1个字符，那么textRange.range.length - text.length=2,选择的起始位置向前移动了两个，
        selectedRange.location -= (textRange.range.length - text.length);
    } else
    {
        
    }
    
    [_mutableText replaceCharactersInRange:textRange.range withString:text];
    
    _text = [_mutableText copy];
    _textContainerView.text = _text;
    _textContainerView.selectedTextRange = selectedRange;
    self.selectedRange = _textContainerView.selectedTextRange;
}



- (UITextRange *)selectedTextRange
{
    return [YHETextRange indexedRangeWithRange:_textContainerView.selectedTextRange];
}


- (void)setSelectedTextRange:(UITextRange *)range
{
    YHETextRange *indexedRange = (YHETextRange *)range;
    _textContainerView.selectedTextRange = indexedRange.range;
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
        [_mutableText replaceCharactersInRange:selectedRange withString:markedText];
        markedTextRange.location = selectedTextRange.location;
        markedTextRange.length = markedText.length;
    }
    else
    {
        [_mutableText insertString:markedText atIndex:selectedRange.location];
        markedTextRange.location = selectedTextRange.location;
        markedTextRange.length = markedText.length;
    }
    
    selectedTextRange = NSMakeRange(selectedRange.location+markedTextRange.location, selectedRange.length);
    
    _text = [_mutableText copy];
    _textContainerView.text = _text;
    _textContainerView.selectedTextRange = selectedTextRange;
    _textContainerView.markedTextRange = markedTextRange;
    self.selectedRange = _textContainerView.selectedTextRange;
    
    
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
    return nil;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range
{
    return nil;
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    return nil;
}

#pragma mark UITextInput - Returning Text Styling Information

- (NSDictionary *)textStylingAtPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction
{
    // This sample assumes all text is single-styled, so this is easy.
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
        [_mutableText replaceCharactersInRange:markedTextRange withString:text];
        selectedTextRange.location = markedTextRange.location+text.length;
        selectedTextRange.length = 0;
        markedTextRange = NSMakeRange(NSNotFound, 0);
    }
    else if (selectedTextRange.length > 0) {
        [_mutableText replaceCharactersInRange:selectedTextRange withString:text];
        [_textContainerView setSelectedTextRange:NSMakeRange(_mutableText.length, 0)];
    }
    else
    {
        [_mutableText insertString:text atIndex:selectedTextRange.location];
        selectedTextRange.location += text.length;
    }
    
    self.text = [_mutableText copy];
    _textContainerView.selectedTextRange = selectedTextRange;
    _textContainerView.markedTextRange = markedTextRange;
    self.selectedRange = _textContainerView.selectedTextRange;
    
}

- (void)deleteBackward
{
    NSRange selectedTextRange = _textContainerView.selectedTextRange;
    NSRange markedTextRange = _textContainerView.markedTextRange;
    
    if (markedTextRange.location != NSNotFound) {
        [_mutableText deleteCharactersInRange:markedTextRange];
        selectedTextRange = NSMakeRange(markedTextRange.location, 0);
        markedTextRange = NSMakeRange(NSNotFound, 0);
    }
    else if (selectedTextRange.length>0) {
        [_mutableText deleteCharactersInRange:selectedTextRange];
        selectedTextRange.length = 0;
    }
    else if(selectedTextRange.location >0)
    {
        selectedTextRange.location --;
        selectedTextRange.length = 1;
        [_mutableText deleteCharactersInRange:selectedTextRange];
        selectedTextRange.length = 0;
    }


    _text = [_mutableText copy];
    _textContainerView.text = _text;
    _textContainerView.selectedTextRange = selectedTextRange;
    _textContainerView.markedTextRange = markedTextRange;
    self.selectedRange = _textContainerView.selectedTextRange;
}

@end

