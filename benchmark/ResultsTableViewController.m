//
//  ResultsTableViewController.m
//  benchmark
//
//  Created by Pavel Stasyuk on 19/05/15.
//  The MIT License (MIT)
//

#import "ResultsTableViewController.h"
#import "BenchmarkResultEntity.h"

#import <MagicalRecord/MagicalRecord.h>
#import <libextobjc/extobjc.h>

#import "ResultDetailsViewController.h"

@interface ResultsTableViewController ()
@property (nonatomic, strong) NSArray *results;
@end

@implementation ResultsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (NSArray *)results
{
    if (_results == nil) {
        NSFetchedResultsController *controller = [BenchmarkResultEntity
                                                  MR_fetchAllGroupedBy:nil
                                                  withPredicate:nil
                                                  sortedBy:@keypath(BenchmarkResultEntity.new, createdAt)
                                                  ascending:NO
                                                  delegate:nil
                                                  inContext:[NSManagedObjectContext MR_defaultContext]];
        _results = controller.fetchedObjects;
    }
    
    return _results;
}

#pragma mark - <TableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.results.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    BenchmarkResultEntity *result = self.results[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ at %@", result.comment, result.createdAt];
    
    return cell;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSUInteger index = [[self.tableView indexPathForSelectedRow] row];
    [segue.destinationViewController setBenchmark:self.results[index]];
}

#pragma mark -

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        BenchmarkResultEntity *entity = self.results[indexPath.row];
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            BenchmarkResultEntity *localEntity = [entity MR_inContext:localContext];
            [localEntity MR_deleteInContext:localContext];
        } completion:^(BOOL success, NSError *error) {
            self.results = nil;
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }];
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

@end
