//
//  SETextMagnifierCaret.m
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/23.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "YHETextMagnifierCaret.h"

@interface YHETextMagnifierCaret ()
{
    CGImageRef _maskRef;
}

@property (weak, nonatomic) UIView *magnifyToView;
@property (assign, nonatomic) CGPoint touchPoint;

@property (strong, nonatomic) UIImage *mask;
@property (strong, nonatomic) UIImage *loupe;
@property (strong, nonatomic) UIImage *loupeFrame;

@end

@implementation YHETextMagnifierCaret

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UIImage *mask = [UIImage imageNamed:@"YHECoreTextView.bundle/kb-loupe-mask"];
        self.mask = mask;
        
        self.loupe = [UIImage imageNamed:@"YHECoreTextView.bundle/kb-loupe-hi"];
        self.loupeFrame = [UIImage imageNamed:@"YHECoreTextView.bundle/kb-loupe-lo"];
        
        CGImageRef maskImageRef = self.mask.CGImage;
        _maskRef = CGImageMaskCreate(CGImageGetWidth(maskImageRef),
                                     CGImageGetHeight(maskImageRef),
                                     CGImageGetBitsPerComponent(maskImageRef),
                                     CGImageGetBitsPerPixel(maskImageRef),
                                     CGImageGetBytesPerRow(maskImageRef),
                                     CGImageGetDataProvider(maskImageRef),
                                     NULL,
                                     true);
    }
    
    return self;
}

- (void)dealloc
{
    CGImageRelease(_maskRef);
}

- (void)setTouchPoint:(CGPoint)point
{
    _touchPoint = point;
    self.center = CGPointMake(point.x, point.y - 65);
}

- (void)showInView:(UIView *)view atPoint:(CGPoint)point
{
    self.frame = CGRectMake(0.0f, 0.0f, self.mask.size.width, self.mask.size.height);
    
    self.magnifyToView = view;
    self.touchPoint = point;
    
    [view addSubview:self];
    
    CGRect frame = self.frame;
    CGPoint center = self.center;
    
    CGRect startFrame = self.frame;
    startFrame.size = CGSizeZero;
    self.frame = startFrame;
    
    CGPoint startPosition = self.center;
    startPosition.x += frame.size.width / 2;
    startPosition.y += frame.size.height;
    self.center = startPosition;
    
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:kNilOptions
                     animations:^
     {
         self.frame = frame;
         self.center = center;
     }
                     completion:NULL];
}

- (void)moveToPoint:(CGPoint)point
{
    self.touchPoint = point;
    [self setNeedsDisplay];
}

- (void)hide
{
    CGRect bounds = self.bounds;
    bounds.size = CGSizeZero;
    
    CGPoint position = self.touchPoint;
    
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:kNilOptions
                     animations:^
     {
         self.bounds = bounds;
         self.center = position;
     }
                     completion:^(BOOL finished)
     {
         self.magnifyToView = nil;
         [self removeFromSuperview];
     }];
}

//- (CTParagraphStyleRef)parserTextParagraphStyle
//{
//    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
//    CTTextAlignment textAlignment = kCTTextAlignmentLeft;
//    CGFloat minLineHeight = 17.0;
//    CGFloat maxLineHeight = 23.0;
//    CGFloat minLineSpacing = 0.0;
//    CGFloat maxLineSpacing = 0.0;
//    
//    CTParagraphStyleSetting styleSetting[] = {
//        {kCTParagraphStyleSpecifierLineBreakMode,sizeof(CTLineBreakMode),(const void *)&lineBreakMode},
//        {kCTParagraphStyleSpecifierAlignment,sizeof(CTTextAlignment),(const void *)&textAlignment},
//        {kCTParagraphStyleSpecifierMinimumLineSpacing,sizeof(CGFloat),(const void *)&minLineSpacing},
//        {kCTParagraphStyleSpecifierMaximumLineSpacing,sizeof(CGFloat),(const void *)&maxLineSpacing},
//        {kCTParagraphStyleSpecifierMinimumLineHeight,sizeof(CGFloat),(const void *)&minLineHeight},
//        {kCTParagraphStyleSpecifierMaximumLineHeight,sizeof(CGFloat),(const void *)&maxLineHeight}
//    };
//    
//    CTParagraphStyleRef styleRef = CTParagraphStyleCreate(styleSetting, sizeof(styleSetting));
//    return styleRef;
//}


- (void)drawRect:(CGRect)rect
{
    CGFloat screenScale = [UIScreen mainScreen].scale;
    
    CGFloat scale = 1.2f;
    CGRect box = CGRectMake(ceilf(self.touchPoint.x - self.mask.size.width / scale / 2),
                            ceilf(self.touchPoint.y - self.mask.size.height / scale / 2),
                            ceilf(self.mask.size.width / scale),
                            ceilf(self.mask.size.height / scale));
    

    UIGraphicsBeginImageContextWithOptions(box.size, YES, screenScale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    UIRectFill(self.magnifyToView.bounds);
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, -CGRectGetMinX(box), -CGRectGetMinY(box));
    [self.magnifyToView.layer renderInContext:context];
    CGContextRestoreGState(context);
    
    UIImage *captureImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    
    CGImageRef captureImageRef = captureImage.CGImage;

    CGImageRef maskedImage = CGImageCreateWithMask(captureImageRef, _maskRef);

    context = UIGraphicsGetCurrentContext();
    
    CGAffineTransform xform = CGAffineTransformMake(1.0,  0.0,
                                                    0.0, -1.0,
                                                    0.0,  0.0);
    CGContextConcatCTM(context, xform);
    
    CGRect area = CGRectMake(0, 0, self.mask.size.width, -self.mask.size.height);
    
    CGContextDrawImage(context, area, self.loupeFrame.CGImage);
    CGContextDrawImage(context, area, maskedImage);
    
    CGImageRelease(maskedImage);
}

@end
#endif
