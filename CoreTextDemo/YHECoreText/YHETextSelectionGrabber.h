//
//  YHETextSelectionGrabber.h
//  CoreTextDemo
//
//  Created by Christ on 14-8-22.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, YHESeletionGrabDotDirection) {
    YHESeletionGrabDotDirectionTop,
    YHESeletionGrabDotDirectionBottom
};

@interface YHETextSelectionGrabber : UIView

@property (nonatomic,assign) BOOL dragging;

@property (nonatomic,assign) YHESeletionGrabDotDirection dotDirection;

@end
