//
//  ViewController.m
//  PerformanceMonitor
//
//  Created by autohome on 2017/6/14.
//  Copyright © 2017年 autohome. All rights reserved.
//

#import "ViewController.h"
#import "PerformanceMonitor.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) CADisplayLink *display;
@property(nonatomic, assign) NSTimeInterval lastInterval;

@property(nonatomic, assign) NSInteger fps;
@property(nonatomic, assign) NSInteger count;

@property(nonatomic, strong) dispatch_semaphore_t semmphore;
@property(nonatomic, assign) CFRunLoopActivity activity;
@property(nonatomic, assign) NSInteger timeoutCount;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    

    PerformanceMonitor *m = [PerformanceMonitor sharedMonitor];
    [m startMonitor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}








- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = @"666";
    cell.textLabel.textColor = [UIColor blueColor];
    for (int i = 0; i<2000; i++) {
        UIView *v = [[UIView alloc] initWithFrame:self.view.frame];
        [cell.contentView addSubview:v];
        [v removeFromSuperview];
    }
    return cell;
}


@end
