//
//  YHETextRange.m
//  CoreTextDemo
//
//  Created by Christ on 14-8-18.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import "YHETextRange.h"
#import "YHETextPosition.h"

@implementation YHETextRange

+ (instancetype)indexedRangeWithRange:(NSRange)range
{
    if (range.location == NSNotFound) {
        return nil;
    }
    
    YHETextRange *textRange = [[YHETextRange alloc] init];
    textRange.range = range;
    return textRange;
}

- (UITextPosition *)start
{
    return [YHETextPosition positionWithIndex:self.range.location];
}

- (UITextPosition *)end
{
    return [YHETextPosition positionWithIndex:self.range.location+self.range.length];
}

- (BOOL)isEmpty
{
    return (self.range.length==0);
}

@end
