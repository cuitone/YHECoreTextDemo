//
//  YHETextContainerView.h
//  CoreTextDemo
//
//  Created by Christ on 14-8-18.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YHETextContainerView : UIView

@property (nonatomic, copy) NSString *text;

@property (nonatomic, strong) UIFont *font;

@property(nonatomic,retain) UIColor *textColor;

@property(nonatomic) NSTextAlignment textAlignment;    // default is NSLeftTextAlignment

@property(nonatomic,getter = isEditing) BOOL editing;

@property (nonatomic,strong) UIColor *markColor;
/**
 *  选择的文本区域，初始为0，如果未选中文本，则显示光标的位置，长度为0
 */
@property (nonatomic,assign) NSRange selectedTextRange;
/**
 *  在输入非英文时会有占位用于替换的文本，显示于选定的区域
 */
@property (nonatomic,assign) NSRange markedTextRange;

- (CGRect)firstRectForRange:(NSRange)range;

- (CGRect)caretRectForPosition:(int )index;

- (NSInteger)closestIndexToPoint:(CGPoint)point;


@end
