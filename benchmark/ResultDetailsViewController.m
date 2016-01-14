//
//  ResultDetailsViewController.m
//  benchmark
//
//  Created by Pavel Stasyuk on 19/05/15.
//  The MIT License (MIT)
//

#import "ResultDetailsViewController.h"
#import "BenchmarkResult.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <MagicalRecord/MagicalRecord.h>

@interface ResultDetailsViewController ()
@property (strong, nonatomic) IBOutlet UILabel *dataCostsLabel;
@property (strong, nonatomic) IBOutlet UILabel *requestsCostLabel;
@property (strong, nonatomic) IBOutlet UILabel *socketRequestCostLabel;
@property (strong, nonatomic) IBOutlet UILabel *socketDataRequestCostLabel;

@property (strong, nonatomic) IBOutlet UITextView *logTextView;
@property (strong, nonatomic) IBOutlet UITextField *commentTextField;
@end

@implementation ResultDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.logTextView.text = [self.benchmark logText];
    self.requestsCostLabel.text = [NSString stringWithFormat:@"Request costs (1st, 2nd, 3d): %d ms, %d ms, %d ms",
                                   (int)([self.benchmark requestCost1].doubleValue * 1000.),
                                   (int)([self.benchmark requestCost2].doubleValue * 1000.),
                                   (int)([self.benchmark requestCost3].doubleValue * 1000.)];
   
    self.dataCostsLabel.text = [NSString stringWithFormat:@"Data costs (100k, 200k, 500k): %d ms, %d ms, %d ms",
                                   (int)([self.benchmark dataCost1].doubleValue * 1000.),
                                   (int)([self.benchmark dataCost2].doubleValue * 1000.),
                                   (int)([self.benchmark dataCost3].doubleValue * 1000.)];
    
    self.socketRequestCostLabel.text = [NSString stringWithFormat:@"Socket request cost: %d ms",
                                    (int)([self.benchmark socketRequestCost].doubleValue * 1000.)];
    
    self.socketDataRequestCostLabel.text = [NSString stringWithFormat:@"Socket data costs (100k, 200k, 500k): %d ms, %d ms, %d ms",
                                            (int)([self.benchmark socketDataCost1].doubleValue * 1000.),
                                            (int)([self.benchmark socketDataCost2].doubleValue * 1000.),
                                            (int)([self.benchmark socketDataCost3].doubleValue * 1000.)];
    
    self.commentTextField.text = [self.benchmark comment];
    
    @weakify(self);

    [[self.commentTextField rac_signalForControlEvents:UIControlEventEditingDidEndOnExit] subscribeNext:^(id x) {
        @strongify(self);
        
        [self.commentTextField resignFirstResponder];
        [self.benchmark setComment:self.commentTextField.text];
        
        if ([self.benchmark isKindOfClass:[NSManagedObject class]]) {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                NSManagedObject *entity = (NSManagedObject *)self.benchmark;
                NSManagedObject *localEntity = [entity MR_inContext:localContext];
                [localEntity setValue:self.commentTextField.text forKey:@keypath(self.benchmark, comment)];
            }];
        }
    }];
}

- (IBAction)handleActionCopyLog:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [self.benchmark logText];
}

@end
