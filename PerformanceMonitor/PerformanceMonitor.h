//
//  PerformanceMonitor.h
//  PerformanceMonitor
//
//  Created by autohome on 2017/6/15.
//  Copyright © 2017年 autohome. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PerformanceMonitor : NSObject

+ (instancetype)sharedMonitor;

- (void)startMonitor;

@end
