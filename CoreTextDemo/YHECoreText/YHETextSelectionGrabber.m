//
//  YHETextSelectionGrabber.m
//  CoreTextDemo
//
//  Created by Christ on 14-8-22.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import "YHETextSelectionGrabber.h"

@interface YHESelectionBrabberDot : UIView

@property (nonatomic,strong) UIBezierPath *path;

@property (nonatomic,strong) UIImage *dotImage;

@end

@implementation YHESelectionBrabberDot

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
        self.dotImage = [UIImage imageNamed:@"YHECoreTextView.bundle/kb-drag-dot.png"];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, rect, self.dotImage.CGImage);
//    CGContextRelease(context);
}

@end

@interface YHETextSelectionGrabber ()

@property (nonatomic,strong) YHESelectionBrabberDot *dotView;
@property (nonatomic,strong) UIView *caretView;

@end

@implementation YHETextSelectionGrabber

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.caretView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 0)];
        [self.caretView setBackgroundColor:[UIColor blueColor]];
        [self addSubview:self.caretView];
        
        self.dotView = [[YHESelectionBrabberDot alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [self addSubview:self.dotView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect caretFrame = self.caretView.frame;
    caretFrame.origin.x = (CGRectGetWidth(self.bounds) - CGRectGetWidth(caretFrame)) / 2;
    caretFrame.size.height = CGRectGetHeight(self.bounds);
    self.caretView.frame = caretFrame;
    
    CGRect dotFrame = self.dotView.frame;
    if (self.dotDirection == YHESeletionGrabDotDirectionTop) {
        dotFrame.origin = CGPointMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(dotFrame)) / 2, -CGRectGetHeight(dotFrame)+CGRectGetHeight(self.dotView.bounds)/2);
    } else {
        dotFrame.origin = CGPointMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(dotFrame)) / 2, CGRectGetHeight(self.bounds)-CGRectGetHeight(self.dotView.bounds)/2);
    }
    self.dotView.frame = dotFrame;
//    [self.dotView setNeedsDisplay];
}

@end
