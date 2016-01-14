//
//  ResultDetailsViewController.h
//  benchmark
//
//  Created by Pavel Stasyuk on 19/05/15.
//  The MIT License (MIT)
//

#import <UIKit/UIKit.h>
@protocol BenchmarkResult;

@interface ResultDetailsViewController : UIViewController
@property (nonatomic, strong) id<BenchmarkResult> benchmark;
@end
