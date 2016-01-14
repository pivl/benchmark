//
//  RunningBenchmarkViewModel.h
//  benchmark
//
//  Created by Pavel Stasyuk on 13/05/15.
//  The MIT License (MIT)
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RunningBenchmarkViewModel : NSObject
@property (nonatomic, strong) NSString *currentAction;
@property (nonatomic, strong) RACCommand *startBenchmarkCommand;
@end
