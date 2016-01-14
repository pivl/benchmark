//
//  TimeInterval.m
//  benchmark
//
//  Created by Pavel Stasyuk on 13/05/15.
//  The MIT License (MIT)
//

#import "TimeInterval.h"

@implementation TimeInterval {
    NSDate *_startDate;
    NSDate *_endDate;
    BOOL _started;
    BOOL _stopped;
}

- (void)start
{
    NSAssert(_started == NO, @"start already called");
    NSAssert(_stopped == NO, @"start called after stop");
    _startDate = [NSDate date];
    _started = YES;
}

- (void)stop
{
    NSAssert(_stopped == NO, @"stopped already called");
    NSAssert(_started == YES, @"start must be called before stop");
    _endDate = [NSDate date];
    _stopped = YES;
}

- (NSTimeInterval)elapsedTime
{
    NSTimeInterval time = [_endDate timeIntervalSinceDate:_startDate];
    return time;
}

- (NSString *)stringInMs
{
    return [NSString stringWithFormat:@"%d ms", (int)(self.elapsedTime * 1000.)];
}

- (BOOL)isRunning
{
    return _started && !_stopped;
}

@end
