//
//  YHETextPosition.m
//  CoreTextDemo
//
//  Created by Christ on 14-8-18.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import "YHETextPosition.h"

@implementation YHETextPosition

+ (instancetype)positionWithIndex:(NSUInteger)index
{
    YHETextPosition *textPosition = [[YHETextPosition alloc] init];
    textPosition.index = index;
    return textPosition;
}

@end
