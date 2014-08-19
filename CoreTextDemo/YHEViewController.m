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
<UITextViewDelegate>

@property (nonatomic,strong) YHETextView *textView;

@property (nonatomic,strong) YHETextView *editableTextView;

@end

@implementation YHEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.view setBackgroundColor:[UIColor lightGrayColor]];
 
//    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 50, 300, 300)];
//    [textView setBackgroundColor:[UIColor whiteColor]];
//    textView.delegate = self;
//    [self.view addSubview:textView];
    
    self.textView = [[YHETextView alloc] initWithFrame:CGRectMake(10, 50, 300, 300)];
    [self.textView setBackgroundColor:[UIColor whiteColor]];
//    [self.textView setText:@"中国驻蒙古国大使王小龙说，“天时”是指两国关系发展迎来重要历史节点，两国都进入以发展为中心、以改善民生为主线的时期；“地利”是指两国互为近邻，有很长的边境线，是天然的合作伙伴；“人和”则指两国领导人都重视双边关系发展，两国民众间的感情不断加深，发展合作的社会舆论基础日益坚实"];
//    [self.textView setTextColor:[UIColor redColor]];
//    self.textView.delegate = self;
    [self.view addSubview:self.textView];
    
//    self.editableTextView = [[APLEditableCoreTextView alloc] initWithFrame:CGRectMake(10, 100, 300, 400)];
//    [self.editableTextView setBackgroundColor:[UIColor grayColor]];
//    [self.view addSubview:self.editableTextView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSLog(@"textView Sub %@",textView.subviews);
}

@end
