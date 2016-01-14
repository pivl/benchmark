//
//  BenchmarkService.m
//  benchmark
//
//  Created by Pavel Stasyuk on 14/05/15.
//  The MIT License (MIT)
//

#import "BenchmarkService.h"
#import <AFNetworking/AFNetworking.h>
#import <Bolts/Bolts.h>
#import <libextobjc/extobjc.h>
#import <SRWebSocket.h>

#import "TimeInterval.h"

#import "BenchmarkServiceResult.h"


// TODO: specify URLs
NSString * const baseURL = @"#";
NSString * const baseURLSocket = @"#";

@interface ResponseSerializer : AFHTTPResponseSerializer
@end

@implementation ResponseSerializer

- (BOOL)validateResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    return YES;
}

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    return data;
}

@end

@interface BenchmarkService() <SRWebSocketDelegate>

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) SRWebSocket *socket;
@property (nonatomic, strong) TimeInterval *socketOpeningInterval;
@property (nonatomic, strong) TimeInterval *managerGetTimeInterval;

// Sockets
@property (nonatomic, strong) BFTaskCompletionSource *connectToSocketCompletionSource;
@property (nonatomic, strong) TimeInterval *currentSocketTime;
@property (nonatomic, strong) NSError *currentSocketError;
@end

@implementation BenchmarkService {
    dispatch_semaphore_t _currentSocketDsema;
}

+ (instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (void)startBenchmark
{
    NSURL *baseURL = [NSURL URLWithString:baseURL];
    self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    self.manager.responseSerializer = [ResponseSerializer new];
    
    __weak typeof(self) _w_self = self;
    __block NSMutableArray *requestResults = [NSMutableArray new];
    __block NSMutableArray *dataResults = [NSMutableArray new];
    __block BenchmarkServiceResult *returnedResult = [BenchmarkServiceResult new];

    NSUInteger dataLengthK = 1000;
    NSUInteger numberOfRequests = 50;
    NSUInteger waitBefore = 40; //seconds
    NSUInteger waitBeforeData = 5;
    
    [[[[[[[[[[[[[[_w_self sequenceOfRequestsWithNumber:3 bytes:0 in:0 sequenceDescription:@"Req.1"] continueWithSuccessBlock:^id(BFTask *task) {
        NSLog(@"%@", task.result);
        [requestResults addObject:task.result];
        return [_w_self sequenceOfRequestsWithNumber:3 bytes:0 in:waitBefore sequenceDescription:@"Req.2"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSLog(@"%@", task.result);
        [requestResults addObject:task.result];
        return [_w_self sequenceOfRequestsWithNumber:3 bytes:0 in:waitBefore sequenceDescription:@"Req.3"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSLog(@"%@", task.result);
        [requestResults addObject:task.result];
        
        return [_w_self sequenceOfRequestsWithNumber:numberOfRequests bytes:100 * dataLengthK in:waitBeforeData sequenceDescription:@"100k Req"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSLog(@"%@", task.result);
        [dataResults addObject:task.result];
        
        return [_w_self sequenceOfRequestsWithNumber:numberOfRequests bytes:200 * dataLengthK in:waitBeforeData sequenceDescription:@"200k Req"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSLog(@"%@", task.result);
        [dataResults addObject:task.result];
        
        return [_w_self sequenceOfRequestsWithNumber:numberOfRequests bytes:500 * dataLengthK in:waitBeforeData sequenceDescription:@"500k Req"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSLog(@"%@", task.result);
        [dataResults addObject:task.result];
        
        [returnedResult setRequestCost1:@(averageValueForIndex(requestResults, 0))];
        [returnedResult setRequestCost2:@(averageValueForIndex(requestResults, 1))];
        [returnedResult setRequestCost3:@(averageValueForIndex(requestResults, 2))];
        
        [returnedResult setDataCost1:@(averageValueInArray(dataResults[0]))];
        [returnedResult setDataCost2:@(averageValueInArray(dataResults[1]))];
        [returnedResult setDataCost3:@(averageValueInArray(dataResults[2]))];
        
        return [BFTask taskWithResult:nil];
    }] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            _w_self.error = task.error;
        }
        else {
            return [_w_self connectToSocket];
        }
        return [BFTask cancelledTask];
    }] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            _w_self.result = returnedResult;
        }
        else if (!task.isCancelled) {
            return [_w_self socketSequenceWithNumberOfRequests:numberOfRequests bytes:5 in:0 sequenceDescription:@"Socket Req."];
        }
        return [BFTask cancelledTask];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSLog(@"%@", task.result);
        [returnedResult setSocketRequestCost:@(averageValueInArray(task.result))];
        
        return [_w_self socketSequenceWithNumberOfRequests:numberOfRequests bytes:100 * dataLengthK in:waitBeforeData sequenceDescription:@"Socket Data 100K"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSLog(@"%@", task.result);
        [returnedResult setSocketDataCost1:@(averageValueInArray(task.result))];
        
        return [_w_self socketSequenceWithNumberOfRequests:numberOfRequests bytes:200 * dataLengthK in:waitBeforeData sequenceDescription:@"Socket Data 200K"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSLog(@"%@", task.result);
        [returnedResult setSocketDataCost2:@(averageValueInArray(task.result))];
        
        return [_w_self socketSequenceWithNumberOfRequests:numberOfRequests bytes:500 * dataLengthK in:waitBeforeData sequenceDescription:@"Socket Data 500K"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSLog(@"%@", task.result);
        [returnedResult setSocketDataCost3:@(averageValueInArray(task.result))];
        
        return [BFTask taskWithResult:nil];
    }] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            _w_self.error = task.error;
        }
        else if (!task.isCancelled) {
            _w_self.result = returnedResult;
        }
        
        return nil;
    }];
}

- (BFTask *)sequenceOfRequestsWithNumber:(NSUInteger)numberOfRequests bytes:(NSUInteger)bytes in:(NSTimeInterval)seconds sequenceDescription:(NSString *)description
{
    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:numberOfRequests];
    
    NSUInteger mseconds = 0;
    __block NSUInteger currentRequest = 0;
    
    NSOperationQueue *operations = [NSOperationQueue new];
    operations.maxConcurrentOperationCount = 1;
    operations.name = @"benchmark.op";
    
    __block NSError *errorOccurred = nil;
    
    void(^blockOperation)() = ^ {
        if (!errorOccurred) {
            dispatch_semaphore_t dsema = dispatch_semaphore_create(0);
            
            [NSThread sleepForTimeInterval:.2];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentOperationDescription = [NSString stringWithFormat:@"Making request %lu", (unsigned long)(currentRequest+1)];
                
                NSString *requestId = [NSString stringWithFormat:@"%@.%lu", description, (unsigned long)currentRequest];
                
                [self managerGetLength:bytes wait:mseconds requestId:requestId success:^(AFHTTPRequestOperation *operation, TimeInterval *time) {
                    [results addObject:@(time.elapsedTime - ((double)mseconds)/1000.)];
                    currentRequest += 1;
                    dispatch_semaphore_signal(dsema);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    self.currentOperationDescription = nil;
                    errorOccurred = error;
                    dispatch_semaphore_signal(dsema);
                }];
            });
            
            dispatch_semaphore_wait(dsema, DISPATCH_TIME_FOREVER);
        }
    };
    
    void(^completionOperation)() = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (errorOccurred) {
                [taskCompletionSource setError:errorOccurred];
            }
            else {
                __block NSString *doneString = [NSString stringWithFormat:@"%@: done\nresults are (", description];
                [results enumerateObjectsUsingBlock:^(NSNumber *result, NSUInteger idx, BOOL *stop) {
                    doneString = [doneString stringByAppendingString:[NSString stringWithFormat:@"%d", (int)(result.doubleValue * 1000.)]];
                    if (idx != results.count - 1) {
                        doneString = [doneString stringByAppendingString:@", "];
                    }
                }];
                doneString = [doneString stringByAppendingString:@") ms"];
                self.currentOperationDescription = doneString;
                [taskCompletionSource setResult:results];
            }
        });
    };
    
    self.currentOperationDescription = [NSString stringWithFormat:@"%@: waiting %.3f seconds", description, seconds];
    operations.suspended = YES;
    
    for (NSUInteger i = 0; i < numberOfRequests; i++) {
        [operations addOperationWithBlock:blockOperation];
    }
    
    [operations addOperationWithBlock:completionOperation];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        operations.suspended = NO;
    });
    
    return taskCompletionSource.task;
}

- (BFTask *)connectToSocket
{
    BFTaskCompletionSource *taskCompletionSouce =[BFTaskCompletionSource taskCompletionSource];
    self.connectToSocketCompletionSource = taskCompletionSouce;
    
    self.socket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:baseURLSocket]];
    self.socket.delegate = self;
    self.socketOpeningInterval = [TimeInterval new];
    self.currentOperationDescription = @"Opening web socket...";
    [self.socketOpeningInterval start];
    [self.socket open];
    
    return taskCompletionSouce.task;
}

- (void)managerGetLength:(NSUInteger)bytes
                    wait:(NSUInteger)wait
               requestId:(NSString *)requestId
                 success:(void (^)(AFHTTPRequestOperation *operation, TimeInterval *responseObject))success
                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self managerGetLength:bytes wait:wait requestId:requestId success:success failure:failure previousFailureError:nil];
}

- (void)managerGetLength:(NSUInteger)bytes
                    wait:(NSUInteger)wait
               requestId:(NSString *)requestId
                 success:(void (^)(AFHTTPRequestOperation *operation, TimeInterval *responseObject))success
                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
    previousFailureError:(NSError *)previousFailureError
{
    __weak typeof(self) _w_self = self;
    __block TimeInterval *timeInterval = [TimeInterval new];
    [timeInterval start];
    
    void(^successBlock)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!_w_self.managerGetTimeInterval) {
            _w_self.managerGetTimeInterval = [TimeInterval new];
            [_w_self.managerGetTimeInterval start];
        }
        
        [timeInterval stop];
        
        if (success) {
            success(operation, timeInterval);
        }
    };
    
    void(^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [_w_self.managerGetTimeInterval stop];
        [timeInterval stop];
        
        _w_self.currentOperationDescription = [NSString stringWithFormat:@"GET failure after %@", _w_self.managerGetTimeInterval.stringInMs];
        _w_self.managerGetTimeInterval = nil;
        
        NSInteger code = error.code;
        NSInteger codeTimeOut = NSURLErrorTimedOut;
        
        if (!previousFailureError && code == NSURLErrorTimedOut) {
            _w_self.currentOperationDescription = [NSString stringWithFormat:@"Time-out error occurred after %@, retrying request", timeInterval.stringInMs];
            [_w_self managerGetLength:bytes wait:wait requestId:requestId success:success failure:failure previousFailureError:error];
        }
        else if (failure) {
            failure(operation, error);
        }
    };
    
    [self.manager GET:@"/test" parameters:@{@"data_length": @(bytes), @"wait": @(wait), @"request_id": requestId} success:successBlock failure:failureBlock];
}

- (BFTask *)socketSequenceWithNumberOfRequests:(NSUInteger)numberOfRequests bytes:(NSUInteger)bytes in:(NSTimeInterval)seconds sequenceDescription:(NSString *)description
{
    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:numberOfRequests];
    
    NSUInteger mseconds = 0;
    __block NSUInteger currentRequest = 0;
    
    NSOperationQueue *operations = [NSOperationQueue new];
    operations.maxConcurrentOperationCount = 1;
    operations.name = @"benchmark.op";
    
    self.currentSocketError = nil;
    self.currentSocketTime = nil;
    
    void(^blockOperation)() = ^ {
        if (!self.currentSocketError && self.socket) {
            _currentSocketDsema = dispatch_semaphore_create(0);
            
            [NSThread sleepForTimeInterval:.2];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentOperationDescription = [NSString stringWithFormat:@"Making socket request %lu", (unsigned long)(currentRequest+1)];
                NSString *requestId = [NSString stringWithFormat:@"%@.%lu", description, (unsigned long)currentRequest];
                [self sendSocketMessageLength:bytes wait:mseconds requestId:requestId];
            });
            
            dispatch_semaphore_wait(_currentSocketDsema, DISPATCH_TIME_FOREVER);
            
            if (self.currentSocketError) {
                self.currentOperationDescription = nil;
            }
            else {
                [results addObject:@(self.currentSocketTime.elapsedTime - ((double)mseconds)/1000.)];
            }
            
            currentRequest +=1;
            self.currentSocketTime = nil;
        }
    };
    
    void(^completionOperation)() = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.currentSocketError) {
                [taskCompletionSource setError:self.currentSocketError];
            }
            else {
                __block NSString *doneString = [NSString stringWithFormat:@"%@: done\nresults are ", description];
                [results enumerateObjectsUsingBlock:^(NSNumber *result, NSUInteger idx, BOOL *stop) {
                    doneString = [doneString stringByAppendingString:[NSString stringWithFormat:@"%d ms", (int)(result.doubleValue * 1000.)]];
                    if (idx != results.count - 1) {
                        doneString = [doneString stringByAppendingString:@", "];
                    }
                }];
                self.currentOperationDescription = doneString;
                [taskCompletionSource setResult:results];
            }
        });
    };
    
    self.currentOperationDescription = [NSString stringWithFormat:@"%@: waiting %.3f seconds", description, seconds];
    operations.suspended = YES;
    
    for (NSUInteger i = 0; i < numberOfRequests; i++) {
        [operations addOperationWithBlock:blockOperation];
    }
    
    [operations addOperationWithBlock:completionOperation];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        operations.suspended = NO;
    });
    
    return taskCompletionSource.task;
}

- (void)sendSocketMessageLength:(NSUInteger)bytes wait:(NSUInteger)wait requestId:(NSString *)requestId
{
    self.currentSocketTime = [TimeInterval new];
    [self.currentSocketTime start];
    if (self.socket.readyState == SR_OPEN) {
        NSString *message = [NSString stringWithFormat:@"{\"data_length\":%lu,\"wait\":%lu,\"request_id\":\"%@\",\"payload\":\"%@\"}",
                             (unsigned long)bytes,
                             (unsigned long)wait,
                             requestId,
                            @"Some info go here"];
        [self.socket send:message];
    }
    else {
        self.currentSocketError = [NSError errorWithDomain:@"com.buymeapie.benchmark" code:9 userInfo:@{NSLocalizedDescriptionKey: @"Socket was closed before all requests made"}];
        dispatch_semaphore_signal(_currentSocketDsema);
    }
}

#pragma mark - Web Socket Delegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    if (self.currentSocketTime.isRunning) {
        [self.currentSocketTime stop];
        NSLog(@"message received:\n%@", message);
        dispatch_semaphore_signal(_currentSocketDsema);
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    [self.socketOpeningInterval stop];
    self.currentOperationDescription = [NSString stringWithFormat:@"Socket opened in %@", self.socketOpeningInterval.stringInMs];
    [self.connectToSocketCompletionSource setResult:self.socketOpeningInterval];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    self.currentOperationDescription = [NSString stringWithFormat:@"WebSocket Error: %@", error];
    
    if (self.socketOpeningInterval.isRunning) {
        [self.socketOpeningInterval stop];
        [self.connectToSocketCompletionSource setError:error];
    }
    
    if (self.currentSocketTime.isRunning) {
        [self.currentSocketTime stop];
        self.currentSocketError = error;
        dispatch_semaphore_signal(_currentSocketDsema);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    self.currentOperationDescription = [NSString stringWithFormat:@"Socket closed code:%lu, reason: %@", (unsigned long)code, reason];
    
    if (self.currentSocketTime.isRunning) {
        [self.currentSocketTime stop];
        dispatch_semaphore_signal(_currentSocketDsema);
    }
    
    self.socket = nil;
}

#pragma mark -

- (void)cancelBenchmark
{
    [self.manager.operationQueue cancelAllOperations];
    self.socket = nil;
    self.result = nil;
    self.error = nil;
    self.currentOperationDescription = nil;
}

static double averageValueForIndex(NSArray *results, NSInteger indexOfInterest)
{
    NSUInteger max = [results[0] count];
    double value = 0;
    for (NSUInteger i = 0; i < max; i++) {
        value += [results[i][indexOfInterest] doubleValue];
    }
    
    return value / (double)max;
}

static double averageValueInArray(NSArray *array)
{
    double max = array.count;
    double value = 0;
    for (NSUInteger i = 0; i < max; i++) {
        value += [array[i] doubleValue];
    }
    
    return value / (double)max;
}

@end
