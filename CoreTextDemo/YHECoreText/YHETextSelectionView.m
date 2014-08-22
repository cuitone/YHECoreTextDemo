//
//  YHETextSelectionView.m
//  CoreTextDemo
//
//  Created by Christ on 14-8-22.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import "YHETextSelectionView.h"
#import "YHETextView.h"
#import "YHETextSelectionGrabber.h"

@interface YHETextView (Private)

- (void)tap:(UITapGestureRecognizer *)tap;
- (void)longPress:(UILongPressGestureRecognizer *)longPress;
- (void)grabSelectionGesture:(UIPanGestureRecognizer *)panGesture;

@end

@interface YHETextSelectionView ()

@property (nonatomic,weak) YHETextView *textView;

@property (nonatomic,strong) YHETextSelectionGrabber *leftGrabber;

@property (nonatomic,strong) YHETextSelectionGrabber *rightGrabber;

@end

@implementation YHETextSelectionView

- (id)initWithFrame:(CGRect)frame textView:(YHETextView *)textView
{
    self.textView = textView;
    self = [self initWithFrame:frame];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initView];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)initView
{
    self.leftGrabber = [[YHETextSelectionGrabber alloc] initWithFrame:CGRectMake(0, 0, 3, 17)];
    [self.leftGrabber setDotDirection:YHESeletionGrabDotDirectionBottom];
    [self addSubview:self.leftGrabber];
    
    self.rightGrabber = [[YHETextSelectionGrabber alloc] initWithFrame:CGRectMake(0, 0, 3, 17)];
    [self.rightGrabber setDotDirection:YHESeletionGrabDotDirectionTop];
    [self addSubview:self.rightGrabber];
    
    [self hideGarbers];
    
    self.singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self.textView action:@selector(tap:)];
    self.singleTapGesture.numberOfTapsRequired = 1;
    self.singleTapGesture.numberOfTouchesRequired = 1;
    self.singleTapGesture.delegate = self;
    [self.textView addGestureRecognizer:self.singleTapGesture];
    
    self.selectionGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self.textView action:@selector(longPress:)];
    self.selectionGesture.numberOfTouchesRequired = 1;
    self.selectionGesture.delegate = self;
    self.selectionGesture.minimumPressDuration = 0.5;
    [self.textView addGestureRecognizer:self.selectionGesture];
    
    self.startGrabGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self.textView action:@selector(grabSelectionGesture:)];
    [self.leftGrabber addGestureRecognizer:self.startGrabGesture];
    
    self.endGrabGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self.textView action:@selector(grabSelectionGesture:)];
    [self.rightGrabber addGestureRecognizer:self.endGrabGesture];

}

- (void)setStartFrame:(CGRect)startFrame endFrame:(CGRect)endFrame
{
    [self.leftGrabber setFrame:startFrame];
    [self.rightGrabber setFrame:endFrame];
}

- (void)showGarbers
{
    [self.leftGrabber setHidden:NO];
    [self.rightGrabber setHidden:NO];
}

- (void)hideGarbers
{
    [self.leftGrabber setHidden:YES];
    [self.rightGrabber setHidden:YES];
}


@end
