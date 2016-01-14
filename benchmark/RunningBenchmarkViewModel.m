//
//  RunningBenchmarkViewModel.m
//  benchmark
//
//  Created by Pavel Stasyuk on 13/05/15.
//  The MIT License (MIT)
//

#import "RunningBenchmarkViewModel.h"

#import "BenchmarkService.h"

@implementation RunningBenchmarkViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    BenchmarkService *service = [BenchmarkService sharedInstance];
    
    RAC(self, currentAction) = RACObserve(service, currentOperationDescription);
    
    __weak typeof(self) _w_self = self;
    
    self.startBenchmarkCommand = [[RACCommand alloc] initWithEnabled:[RACSignal return:@YES] signalBlock:^RACSignal *(id input) {
        return [_w_self executeBenchmarkSignal];
    }];
}

- (RACSignal *)executeBenchmarkSignal
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        BenchmarkService *servive = [BenchmarkService sharedInstance];
        
        NSArray *signals = @[RACObserve(servive, result), RACObserve(servive, error)];
        [[RACSignal combineLatest:signals reduce:^id(id result, NSError *error) {
            return error ? error : result;
        }] subscribeNext:^(id result) {
            if ([result isKindOfClass:[NSError class]]) {
                [subscriber sendError:result];
                [subscriber sendCompleted];
            }
            else if (result != nil) {
                [subscriber sendNext:result];
                [subscriber sendCompleted];
            }
        }];
        
        [servive startBenchmark];
        
        return [RACDisposable disposableWithBlock:^{
            [servive cancelBenchmark];
        }];
    }];
    
    return signal;
}

@end
