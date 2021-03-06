//
//  BenchmarkResultEntity.h
//  benchmark
//
//  Created by Pavel Stasyuk on 18/05/15.
//  The MIT License (MIT)
//

#import <CoreData/CoreData.h>
#import "BenchmarkResult.h"

@interface BenchmarkResultEntity : NSManagedObject <BenchmarkResult>

@property (nonatomic, retain) NSNumber * requestCost1;
@property (nonatomic, retain) NSNumber * requestCost2;
@property (nonatomic, retain) NSNumber * requestCost3;
@property (nonatomic, retain) NSNumber * dataCost1;
@property (nonatomic, retain) NSNumber * dataCost2;
@property (nonatomic, retain) NSNumber * dataCost3;

@property (nonatomic, retain) NSNumber *socketRequestCost;
@property (nonatomic, retain) NSNumber *socketDataCost1;
@property (nonatomic, retain) NSNumber *socketDataCost2;
@property (nonatomic, retain) NSNumber *socketDataCost3;

@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSString * logText;
@property (nonatomic, retain) NSDate * createdAt;

@end
