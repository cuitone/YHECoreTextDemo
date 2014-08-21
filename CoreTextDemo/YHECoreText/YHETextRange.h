//
//  YHETextRange.h
//  CoreTextDemo
//
//  Created by Christ on 14-8-18.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YHETextRange : UITextRange

@property (nonatomic) NSRange range;
+ (instancetype)indexedRangeWithRange:(NSRange)range;

@end
