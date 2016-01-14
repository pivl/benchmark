//
//  BenchmarkService.h
//  benchmark
//
//  Created by Pavel Stasyuk on 14/05/15.
//  The MIT License (MIT)
//

#import <Foundation/Foundation.h>

@protocol BenchmarkResult;

@interface BenchmarkService : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong) NSString *currentOperationDescription;
@property (nonatomic, strong) id<BenchmarkResult> result;
@property (nonatomic, strong) NSError *error;

- (void)startBenchmark;
- (void)cancelBenchmark;

@end
