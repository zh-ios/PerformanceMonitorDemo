//
//  ViewController.m
//  PerformanceMonitor
//
//  Created by autohome on 2017/6/14.
//  Copyright © 2017年 autohome. All rights reserved.
//

#import "ViewController.h"
#import <sys/sysctl.h>
#import <mach/mach.h>

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
    
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    self.display = displaylink;
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    
    _semmphore = dispatch_semaphore_create(0);
    _timeoutCount = 0;
    
    // runloop 运行上下文环境
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)(self),
        &CFRetain,
        &CFRelease,
        NULL
    };

    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runloopObserver, &context);
    
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
 
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (YES) {
            // zero = success else timeout
            // // 假定连续5次超时30ms认为卡顿(当然也包含了单次超时250ms)
            long state = dispatch_semaphore_wait(self.semmphore, dispatch_time(DISPATCH_TIME_NOW, 30*NSEC_PER_MSEC));
            if (state != 0) {
                if (self.activity == kCFRunLoopBeforeSources || self.activity == kCFRunLoopAfterWaiting) {
                    self.timeoutCount += 1;
                    if (self.timeoutCount < 5) {
                        continue;
                    } else {
                        NSLog(@"🍉🍉🍉🍉🍉🍉🍉可能超时了");
                        self.timeoutCount = 0;
                        // 这里可以记录当前的堆栈信息
                    }
                }
            }
            self.timeoutCount = 0;
        }
    });

    
    
    
    
    
    
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    float userage = [self usedMemory] / [self availableMemory];
    NSLog(@"当前cpu使用率===========%.2f",userage);
    
}

static void runloopObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
//    NSLog(@"-------%ld",activity);
  
    ViewController *moniotr = (__bridge ViewController*)info;

    moniotr.activity = activity;

    dispatch_semaphore_signal(moniotr.semmphore);
}



- (void)handleDisplayLink:(CADisplayLink *)link {
    if (self.lastInterval == 0) {
        self.lastInterval = link.timestamp;
        return;
    }
    self.count++;
    NSTimeInterval interval = link.timestamp;
    // 每隔一秒记录一次
    NSTimeInterval delta = interval - self.lastInterval;
    if (delta < 1) {
        return;
    }
    self.lastInterval = link.timestamp;
    self.fps = self.count / delta;
    self.count = 0;
    NSLog(@"当前fps*********%ld",self.fps);
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



- (double)availableMemory {
    
    vm_statistics_data_t vmStats;
    
    mach_msg_type_number_t infoCount =HOST_VM_INFO_COUNT;
    
    kern_return_t kernReturn = host_statistics(mach_host_self(),
                                               
                                               HOST_VM_INFO,
                                               
                                               (host_info_t)&vmStats,
                                               
                                               &infoCount);

    if (kernReturn != KERN_SUCCESS) {
        
        return NSNotFound;
        
    }

    return ((vm_page_size *vmStats.free_count) /1024.0) / 1024.0;
    
}

// 获取当前任务所占用的内存（单位：MB）

- (double)usedMemory {
    
    task_basic_info_data_t taskInfo;
    
    mach_msg_type_number_t infoCount =TASK_BASIC_INFO_COUNT;
    
    kern_return_t kernReturn =task_info(mach_task_self(),
                                        
                                        TASK_BASIC_INFO,
                                        
                                        (task_info_t)&taskInfo, 
                                        
                                        &infoCount);
    
    
    
    if (kernReturn != KERN_SUCCESS
        
        ) {
        
        return NSNotFound;
        
    }
    
    
    
    return taskInfo.resident_size / 1024.0 / 1024.0;
    
}

@end
