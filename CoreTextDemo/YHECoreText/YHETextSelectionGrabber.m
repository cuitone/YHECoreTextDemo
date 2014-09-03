//
//  YHETextSelectionGrabber.m
//  CoreTextDemo
//
//  Created by Christ on 14-8-22.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import "YHETextSelectionGrabber.h"

@interface YHETextSelectionCaret : UIView

@property (nonatomic,strong) UIBezierPath *path;

@end

@implementation YHETextSelectionCaret

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 10, 10)];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:19.0/255.0 green:84.0/255.0 blue:214.0/255.0 alpha:1.0].CGColor);
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGRect drawRect = CGRectMake(center.x-1, 0, 2, CGRectGetHeight(rect));
    CGContextAddPath(context, self.path.CGPath);
    CGContextAddRect(context, drawRect);
    CGContextDrawPath(context, kCGPathFill);
}

@end

@interface YHETextSelectionGrabber ()

@property (nonatomic,strong) YHETextSelectionCaret *textSelectionCaret;


@end

@implementation YHETextSelectionGrabber

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.textSelectionCaret = [[YHETextSelectionCaret alloc] initWithFrame:CGRectMake(0, 0, 10, 23)];

        [self addSubview:self.textSelectionCaret];
//        [self setBackgroundColor:[UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.5]];
    }
    return self;
}

- (void)setDotDirection:(YHESeletionGrabDotDirection)dotDirection
{
    _dotDirection = dotDirection;
    if (_dotDirection == YHESeletionGrabDotDirectionTop) {
        [self.textSelectionCaret setTransform:CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI)];
    }


}

- (void)setFrame:(CGRect)frame
{
    CGRect newFrame = CGRectZero;
    
    CGPoint newCenter = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    if (_dotDirection == YHESeletionGrabDotDirectionTop) {
        newFrame = CGRectMake(newCenter.x-27, newCenter.y - 7, 30, 23);
        [super setFrame:newFrame];
        [self.textSelectionCaret setCenter:CGPointMake(CGRectGetWidth(newFrame)-CGRectGetWidth(self.textSelectionCaret.bounds)/2, CGRectGetHeight(self.textSelectionCaret.bounds)/2)];

    }
    else{
        newFrame = CGRectMake(newCenter.x-8, newCenter.y - 16, 30, 23);
        [super setFrame:newFrame];
        [self.textSelectionCaret setCenter:CGPointMake(CGRectGetWidth(self.textSelectionCaret.bounds)/2, CGRectGetHeight(self.textSelectionCaret.bounds)/2)];
    }

}

@end
