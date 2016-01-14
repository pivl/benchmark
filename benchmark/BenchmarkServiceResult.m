//
//  BenchmarkServiceResult.m
//  benchmark
//
//  Created by Pavel Stasyuk on 18/05/15.
//  The MIT License (MIT)
//

#import "BenchmarkServiceResult.h"

@implementation BenchmarkServiceResult

- (NSString *)description
{
    return [NSString stringWithFormat:@"\nRequests(%d,%d,%d),\nData(%d,%d,%d)\nSocket(%d)\nSocket Data(%d,%d,%d)",
            (int)(self.requestCost1.floatValue * 1000.),
            (int)(self.requestCost2.floatValue * 1000.),
            (int)(self.requestCost3.floatValue * 1000.),
            (int)(self.dataCost1.floatValue * 1000.),
            (int)(self.dataCost2.floatValue * 1000.),
            (int)(self.dataCost3.floatValue * 1000.),
            (int)(self.socketRequestCost.floatValue * 1000.),
            (int)(self.socketDataCost1.floatValue * 1000.),
            (int)(self.socketDataCost2.floatValue * 1000.),
            (int)(self.socketDataCost3.floatValue * 1000.)];
}

@end
