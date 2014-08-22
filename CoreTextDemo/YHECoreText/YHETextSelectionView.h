//
//  YHETextSelectionView.h
//  CoreTextDemo
//
//  Created by Christ on 14-8-22.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@class  YHETextView;
@interface YHETextSelectionView : UIView
<UIGestureRecognizerDelegate>

- (id)initWithFrame:(CGRect)frame textView:(YHETextView *)textView;

@property (nonatomic,strong) UITapGestureRecognizer *singleTapGesture;

@property (nonatomic,strong) UILongPressGestureRecognizer *selectionGesture;

@property (nonatomic,strong) UIPanGestureRecognizer *startGrabGesture;

@property (nonatomic,strong) UIPanGestureRecognizer *endGrabGesture;

- (void)setStartFrame:(CGRect)startFrame endFrame:(CGRect)endFrame;

- (void)showGarbers;

- (void)hideGarbers;

@end
