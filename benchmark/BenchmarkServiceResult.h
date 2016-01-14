//
//  BenchmarkServiceResult.h
//  benchmark
//
//  Created by Pavel Stasyuk on 18/05/15.
//  The MIT License (MIT)
//
#import <Foundation/Foundation.h>
#import "BenchmarkResult.h"

@interface BenchmarkServiceResult : NSObject <BenchmarkResult>

@property (nonatomic, strong) NSNumber *requestCost1;
@property (nonatomic, strong) NSNumber *requestCost2;
@property (nonatomic, strong) NSNumber *requestCost3;

@property (nonatomic, strong) NSNumber *dataCost1;
@property (nonatomic, strong) NSNumber *dataCost2;
@property (nonatomic, strong) NSNumber *dataCost3;

@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSString *logText;

@property (nonatomic, strong) NSNumber *socketRequestCost;
@property (nonatomic, strong) NSNumber *socketDataCost1;
@property (nonatomic, strong) NSNumber *socketDataCost2;
@property (nonatomic, strong) NSNumber *socketDataCost3;

@end
