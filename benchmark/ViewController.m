//
//  ViewController.m
//  benchmark
//
//  Created by Pavel Stasyuk on 12/05/15.
//  The MIT License (MIT)
//

#import "ViewController.h"

#import <MagicalRecord/MagicalRecord.h>

#import "RunningBenchmarkViewModel.h"
#import "BenchmarkResult.h"
#import "BenchmarkResultEntity.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIButton *startButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UITextView *logTextView;

@property (nonatomic, strong) RunningBenchmarkViewModel *viewModel;
@end

@implementation ViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewModel = [RunningBenchmarkViewModel new];
    self.startButton.rac_command = self.viewModel.startBenchmarkCommand;
    
    [self.activityIndicator startAnimating];
    RAC(self, activityIndicator.hidden) = self.startButton.rac_command.executing.not;
    
    __weak typeof(self) _w_self = self;

    [RACObserve(self, viewModel.currentAction) subscribeNext:^(NSString *line) {
        if (line) {
            [_w_self appendLine:line];
        }
    }];
    
    [self.viewModel.startBenchmarkCommand.executionSignals subscribeNext:^(RACSignal *signal) {
        [signal subscribeNext:^(id<BenchmarkResult> result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *line = [NSString stringWithFormat:@"Overall results are: %@ in ms", result];
                [_w_self appendLine:line];
                [_w_self commitResults:result];
            });
        }];
    }];
    
    [self.viewModel.startBenchmarkCommand.executing subscribeNext:^(NSNumber *value) {
        if ([value isEqual:@YES]) {
            _w_self.logTextView.text = @"";
        }
        [UIApplication sharedApplication].idleTimerDisabled = [value boolValue];
    }];
    
    [self.viewModel.startBenchmarkCommand.errors subscribeNext:^(NSError *error) {
        if (error) {
            [_w_self appendLine:error.description];
        }
    }];
}

- (IBAction)handleActionViewResults:(id)sender
{
    [self performSegueWithIdentifier:@"viewResults" sender:self];
}

- (void)appendLine:(NSString *)line
{
    NSString *text = self.logTextView.text;
    text = [text stringByAppendingString:line];
    text = [text stringByAppendingString:@"\n"];
    self.logTextView.text = text;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (text.length > 3) {
            CGPoint bottomOffset = CGPointMake(0, self.logTextView.contentSize.height - self.logTextView.bounds.size.height);
            [self.logTextView setContentOffset:bottomOffset animated:NO];
        }
    });
}

- (void)commitResults:(id<BenchmarkResult>)result
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        BenchmarkResultEntity *entity = [BenchmarkResultEntity MR_createInContext:localContext];
        entity.logText = self.logTextView.text;
        entity.requestCost1 = [result requestCost1];
        entity.requestCost2 = [result requestCost2];
        entity.requestCost3 = [result requestCost3];
        entity.dataCost1 = [result dataCost1];
        entity.dataCost2 = [result dataCost2];
        entity.dataCost3 = [result dataCost3];
        entity.comment = [result comment];
        entity.socketRequestCost = [result socketRequestCost];
        entity.socketDataCost1 = [result socketDataCost1];
        entity.socketDataCost2 = [result socketDataCost2];
        entity.socketDataCost3 = [result socketDataCost3];
        entity.createdAt = [NSDate date];
    }];
}

@end
