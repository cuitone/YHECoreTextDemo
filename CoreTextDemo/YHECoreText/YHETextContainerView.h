//
//  YHETextContainerView.h
//  CoreTextDemo
//
//  Created by Christ on 14-8-18.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "YHETextSelectionView.h"

@class YHETextContainerView;
@class YHECaretView;

@protocol YHETextContainerViewDelegate <NSObject>

@required

- (BOOL)containerView:(YHETextContainerView *)containerView shouldDrawEmotionWithTag:(NSString *)tag;

- (UIImage *)containerView:(YHETextContainerView *)containerView willDrawEmotionWithTag:(NSString *)tag;

- (void)containerViewDidChangeFrame:(YHETextContainerView *)containerView;

@end

@interface YHETextContainerView : UIView

@property (nonatomic, copy) NSString *text;

@property (nonatomic, strong) UIFont *font;

@property(nonatomic,retain) UIColor *textColor;

@property(nonatomic) NSTextAlignment textAlignment;    // default is NSLeftTextAlignment

@property(nonatomic,getter = isEditing) BOOL editing;

@property (nonatomic,strong) UIColor *markColor;

@property (nonatomic,weak) id<YHETextContainerViewDelegate> delegate;

/**
 *  选择的文本区域，初始为0，如果未选中文本，则显示光标的位置，长度为0
 */
@property (nonatomic,assign) NSRange selectedTextRange;
/**
 *  在输入非英文时会有占位用于替换的文本，显示于选定的区域
 */
@property (nonatomic,assign) NSRange markedTextRange;

@property (nonatomic,strong) NSMutableDictionary *regexDict;

@property (nonatomic,strong) YHETextSelectionView *textSelectionView;

- (CGRect)firstRectForRange:(NSRange)range;

- (CGRect)caretRectForPosition:(int)index;

- (NSInteger)closestIndexToPoint:(CGPoint)point;

- (NSInteger)closestIndexForRichTextFromPoint:(CGPoint)point;

/**
 *  选择两个区域交叉的区域
 */
+ (NSRange)RangeIntersection:(NSRange)first WithSecond:(NSRange)second;

/**
 *  选择两个交叉区域所包含的最大区域，如果无交叉，返回NSNoFound
 */
+ (NSRange)RangeEncapsulateWithIntersection:(NSRange)first WithSecond:(NSRange)second;


@end

@interface YHETextContainerView ()
{
    CTFramesetterRef _ctFrameSetter;
    CTFrameRef _ctFrame;
}

@property (nonatomic,strong) NSMutableDictionary *attributes;

@property (nonatomic,strong) YHECaretView *caretView;

@end
