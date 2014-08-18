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

@property(nonatomic) NSRange selectedRange;

@property(nonatomic,getter=isEditable) BOOL editable;

@property(nonatomic,getter = isEditing) BOOL editing;

@property (nonatomic,assign) NSRange markedTextRange;

- (CGRect)firstRectForRange:(NSRange)range;

- (CGRect)caretRectForPosition:(int )index;

- (NSArray *)selectionRectsForRange:(UITextRange *)range;

- (NSInteger)closestIndexToPoint:(CGPoint)point;

@end
