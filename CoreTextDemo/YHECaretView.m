//
//  YHECaretView.m
//  CoreTextDemo
//
//  Created by Christ on 14-8-18.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import "YHECaretView.h"

static const NSTimeInterval InitialBlinkDelay = 0.7;
static const NSTimeInterval BlinkRate = 0.5;

@interface YHECaretView ()

@property (nonatomic) NSTimer *blinkTimer;

@end

@implementation YHECaretView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor blueColor];
    }
    return self;
}

- (void)blink
{
    self.hidden = !self.hidden;
}

- (void)didMoveToSuperview
{
    if (self.superview) {
        self.blinkTimer = [NSTimer scheduledTimerWithTimeInterval:BlinkRate target:self selector:@selector(blink) userInfo:nil repeats:YES];
        [self delayBlink];
    }
    else
    {
        [self.blinkTimer invalidate];
        self.blinkTimer = nil;
    }
}

- (void)delayBlink
{
    self.hidden = NO;
    [self.blinkTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:InitialBlinkDelay]];
    
}

- (void)dealloc
{
    [_blinkTimer invalidate];
}

@end
