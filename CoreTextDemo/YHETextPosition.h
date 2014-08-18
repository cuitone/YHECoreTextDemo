//
//  YHETextPosition.h
//  CoreTextDemo
//
//  Created by Christ on 14-8-18.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YHETextPosition : UITextPosition

@property (nonatomic,assign) NSUInteger index;

@property (nonatomic,assign) id <UITextInputDelegate> inputDelegate;

+ (instancetype)positionWithIndex:(NSUInteger)index;

@end
