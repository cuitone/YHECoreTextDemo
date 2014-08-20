//
//  YHETextView.h
//  CoreTextDemo
//
//  Created by Christ on 14-8-14.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YHETextView;

@protocol YHETextViewDelegate <NSObject, UIScrollViewDelegate>

@optional

- (BOOL)textViewShouldBeginEditing:(YHETextView *)textView;
- (BOOL)textViewShouldEndEditing:(YHETextView *)textView;

- (void)textViewDidBeginEditing:(YHETextView *)textView;
- (void)textViewDidEndEditing:(YHETextView *)textView;

- (BOOL)textView:(YHETextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)textViewDidChange:(YHETextView *)textView;

- (void)textViewDidChangeSelection:(YHETextView *)textView;

- (BOOL)textView:(YHETextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange NS_AVAILABLE_IOS(7_0);
- (BOOL)textView:(YHETextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange NS_AVAILABLE_IOS(7_0);

- (BOOL)textView:(YHETextView *)textView shouldDrawEmotionWithTag:(NSString *)tag;
- (UIImage *)textView:(YHETextView *)textView willDrawEmotionWithTag:(NSString *)tag;

@end

extern  NSString * const kRegexYohoEmotion;

@interface YHETextView : UIScrollView <UITextInput>

@property(nonatomic,assign) id<YHETextViewDelegate> delegate;
//用于持有实际被输入的文本
@property(nonatomic,copy) NSString *text;
@property(nonatomic,retain) UIFont *font;
@property(nonatomic,retain) UIColor *textColor;
@property(nonatomic) NSTextAlignment textAlignment;    // default is NSLeftTextAlignment
@property(nonatomic) NSRange selectedRange;
@property(nonatomic,getter=isEditable) BOOL editable;

@property(nonatomic,readonly) NSMutableDictionary *regexDict;

@end
