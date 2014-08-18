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

@end

@implementation YHETextView

@synthesize inputDelegate = _inputDelegate;
@synthesize indicatorStyle = _indicatorStyle;
@synthesize markedTextStyle = _markedTextStyle;

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
    _textContainerView = [[YHETextContainerView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 100)];
    [self addSubview:_textContainerView];
    [_textContainerView setUserInteractionEnabled:NO];
//    self.contentSize = _textContainerView.bounds.size;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.delegate = self;
    [self addGestureRecognizer:tap];
    
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

#pragma makr - Actions

- (void)tap:(UITapGestureRecognizer *)tap
{
    if (self.isFirstResponder) {
        [self.inputDelegate selectionWillChange:self];
        
        NSInteger index = [_textContainerView closestIndexToPoint:[tap locationInView:_textContainerView]];
        [_textContainerView setSelectedRange:NSMakeRange(index, 0)];
        [_textContainerView setEditing:YES];
        [self.inputDelegate selectionDidChange:self];
    }
    else
    {
    
        [self becomeFirstResponder];
    }
}

#pragma mark - 属性存取器重写

- (void)setText:(NSString *)text
{
    if (_text != text) {
        _text = text;
        _textContainerView.text = _text;
    }
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
    NSRange selectedRange = _textContainerView.selectedRange;
    if ((textRange.range.location+textRange.range.length) <= selectedRange.location) {
        selectedRange.location -= (textRange.range.length - text.length);
    } else
    {
        
    }
    
    [_mutableText replaceCharactersInRange:selectedRange withString:text];
    
    _text = _mutableText;
    _textContainerView.text = _text;
    _textContainerView.selectedRange = selectedRange;
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
//    NSRange selectedRange = _textContainerView.selectedRange;
}

- (void)unmarkText
{
    
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
    NSRange range = NSMakeRange(MIN(aFromPosition.index, aToPosition.index), ABS(aFromPosition.index-aToPosition.index));
    
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
    return [self convertRect:rect fromView:_textContainerView];
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
    NSRange selectedTextRange = _textContainerView.selectedRange;
    
    if (selectedTextRange.length > 0) {
        [_mutableText replaceCharactersInRange:selectedTextRange withString:text];
        [_textContainerView setSelectedRange:NSMakeRange(_mutableText.length, 0)];
    }
    else
    {
        [_mutableText insertString:text atIndex:_textContainerView.selectedRange.location];
    }
    
    self.text = _mutableText;
    self.selectedRange = _textContainerView.selectedRange;
    
}

- (void)deleteBackward
{
    NSRange selectedTextRange = _textContainerView.selectedRange;
    if (selectedTextRange.length>0) {
        [_mutableText deleteCharactersInRange:selectedTextRange];
        [_textContainerView setSelectedRange:NSMakeRange(_mutableText.length, 0)];
    }
    else if(selectedTextRange.location >0)
    {
        selectedTextRange.location --;
        selectedTextRange.length = 1;
        [_mutableText deleteCharactersInRange:selectedTextRange];
        selectedTextRange.length = 0;
        [_textContainerView setSelectedRange:selectedTextRange];
    }
    
    self.text = _mutableText;
    self.selectedRange = _textContainerView.selectedRange;
}

@end





