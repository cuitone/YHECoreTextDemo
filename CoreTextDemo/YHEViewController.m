//
//  YHEViewController.m
//  CoreTextDemo
//
//  Created by Christ on 14-8-12.
//  Copyright (c) 2014年 NewPower Co. All rights reserved.
//

#import "YHEViewController.h"
#import "YHETextView.h"
//#import "APLEditableCoreTextView.h"

@interface YHEViewController ()
<YHETextViewDelegate>

@property (nonatomic,strong) YHETextView *textView;

@property (nonatomic,strong) YHETextView *editableTextView;

@end

@implementation YHEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.view setBackgroundColor:[UIColor lightGrayColor]];
    
    self.textView = [[YHETextView alloc] initWithFrame:CGRectMake(10, 50, 300, 300)];
    [self.textView setBackgroundColor:[UIColor whiteColor]];
    self.textView.delegate = self;
    [self.textView.regexDict setObject:@"\\[[A-Za-z0-9]{2}\\]" forKey:kRegexYohoEmotion];
//    [self.textView.regexDict setObject:@"\\[[\u4E00-\u9FFF]{2}\\]" forKey:kRegexYohoEmotion];
    [self.textView setText:@"中国驻蒙古国大使王小龙说，“天时”是指两国关系发展迎来重要历史节点，两国都进入以发展为中心、以改善民生为主线的时期；“地利”是指两国互为近邻，有很长的边境线，是天然的合作伙伴；“人和”则指[ab]两国领导人都重视双边关系发展，两[cd]国民众间的感情不断加深，发展合作的社会舆论基础日益坚实"];
    [self.textView setTextColor:[UIColor redColor]];

    [self.view addSubview:self.textView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textViewShouldBeginEditing:(YHETextView *)textView
{
    return YES;
}

- (BOOL)textViewShouldEndEditing:(YHETextView *)textView
{
    return YES;
}

- (void)textViewDidBeginEditing:(YHETextView *)textView
{
 
}
- (void)textViewDidEndEditing:(YHETextView *)textView
{
    
}

- (BOOL)textView:(YHETextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (text.length==0) {
        NSString *subStr = [textView.text substringWithRange:range];
        NSLog(@"Delete Text %@",subStr);
    }
    return YES;
}

- (BOOL)textView:(YHETextView *)textView shouldDrawEmotionWithTag:(NSString *)tag
{
    NSDictionary *aDict = @{@"ab": @"publish_face_B1",@"cd":@"publish_face_B2"};
    return [aDict.allKeys containsObject:tag];
}

- (UIImage *)textView:(YHETextView *)textView willDrawEmotionWithTag:(NSString *)tag
{
    NSDictionary *aDict = @{@"ab": @"publish_face_B1",@"cd":@"publish_face_B2"};
    UIImage *image = [UIImage imageNamed:aDict[tag]];
    return image;
}


- (void)textViewDidChange:(YHETextView *)textView
{
    
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    
}




@end
