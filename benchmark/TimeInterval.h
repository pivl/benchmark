//
//  TimeInterval.h
//  benchmark
//
//  Created by Pavel Stasyuk on 13/05/15.
//  The MIT License (MIT)
//

#import <Foundation/Foundation.h>

@interface TimeInterval : NSObject

- (void)start;
- (void)stop;
- (NSTimeInterval)elapsedTime;
- (NSString *)stringInMs;
- (BOOL)isRunning;

@end
