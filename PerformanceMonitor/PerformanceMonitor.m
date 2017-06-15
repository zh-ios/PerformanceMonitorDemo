//
//  PerformanceMonitor.m
//  PerformanceMonitor
//
//  Created by autohome on 2017/6/15.
//  Copyright © 2017年 autohome. All rights reserved.
//

#import "PerformanceMonitor.h"
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <mach/mach.h>

@interface PerformanceMonitor ()

@property(nonatomic, strong) CADisplayLink *display;
@property(nonatomic, assign) NSTimeInterval lastInterval;

@property(nonatomic, assign) NSInteger fps;
@property(nonatomic, assign) NSInteger count;

@property(nonatomic, strong) dispatch_semaphore_t semmphore;
@property(nonatomic, assign) CFRunLoopActivity activity;
@property(nonatomic, assign) NSInteger timeoutCount;

@property(nonatomic, strong) dispatch_source_t timer;

@end

@implementation PerformanceMonitor

+ (instancetype)sharedMonitor {
    static PerformanceMonitor *monitoer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (monitoer == nil) {
            monitoer = [[self alloc] init];
        }
    });
    return monitoer;
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)startMonitor {
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    self.display = displaylink;
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    
    self.semmphore = dispatch_semaphore_create(0);
    self.timeoutCount = 0;
    
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
    
    //
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    self.timer = timer;
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1000*NSEC_PER_MSEC, 0);
    dispatch_source_set_event_handler(timer, ^{
        NSLog(@"-----%.2f",[self cpu_usage]);
        
    });
    dispatch_resume(timer);
 
}



/*!
 @abstract   runloop 监听回调
 */
static void runloopObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    //    NSLog(@"-------%ld",activity);
    
    PerformanceMonitor *moniotr = (__bridge PerformanceMonitor*)info;
    
    moniotr.activity = activity;
    
    dispatch_semaphore_signal(moniotr.semmphore);
}

/*!
    定时器回调
 */
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


- (float)cpu_usage {
    kern_return_t			kr = { 0 };
    task_info_data_t		tinfo = { 0 };
    mach_msg_type_number_t	task_info_count = TASK_INFO_MAX;
    
    kr = task_info( mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count );
    if ( KERN_SUCCESS != kr )
        return 0.0f;
    
    task_basic_info_t		basic_info = { 0 };
    thread_array_t			thread_list = { 0 };
    mach_msg_type_number_t	thread_count = { 0 };
    
    thread_info_data_t		thinfo = { 0 };
    thread_basic_info_t		basic_info_th = { 0 };
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads( mach_task_self(), &thread_list, &thread_count );
    if ( KERN_SUCCESS != kr )
        return 0.0f;
    
    long	tot_sec = 0;
    long	tot_usec = 0;
    float	tot_cpu = 0;
    
    for ( int i = 0; i < thread_count; i++ )
    {
        mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
        
        kr = thread_info( thread_list[i], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count );
        if ( KERN_SUCCESS != kr )
            return 0.0f;
        
        basic_info_th = (thread_basic_info_t)thinfo;
        if ( 0 == (basic_info_th->flags & TH_FLAGS_IDLE) )
        {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
        }
    }
    
    kr = vm_deallocate( mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t) );
    if ( KERN_SUCCESS != kr )
        return 0.0f;
    
    return tot_cpu;
}


@end
