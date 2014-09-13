//
//  MasterViewController.m
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "Event.h"
#import "EventManager.h"
#import "Constants.h"

@interface MasterViewController ()
{
    BOOL _isLoadingData;
    BOOL _updateAtStartUp;
    
    NSMutableArray *_filteredEventArray;
}

@end

@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _filteredEventArray = [[NSMutableArray alloc] init];
    
    NSTimeInterval timeSinceLastUpdate = 0;
    
    // Calculate time since last update if it is not the app's first run.
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"eventsRefreshTime"] != nil) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"];
        NSDate *lastRefreshDate = [formatter dateFromString:[[NSUserDefaults standardUserDefaults] objectForKey:@"eventsRefreshTime"]];
        timeSinceLastUpdate = [[NSDate date] timeIntervalSinceDate:lastRefreshDate];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"eventsRefreshTime"] == nil || timeSinceLastUpdate > kTimeIntervalBetweenAutomaticUpdates) {
        
        _updateAtStartUp = YES;
        [self updateEventData];
        
    } else {
        
        _updateAtStartUp = NO;
        [self performFetch];
    }
}

- (void)updateEventData
{
    _isLoadingData = YES;
    
    if (_fetchedResultsController != nil) {
        _fetchedResultsController = nil;
        [self.tableView reloadData];
    }
    
    if (!_updateAtStartUp) {
        [self.refreshControl beginRefreshing];
    }
    
    [[EventManager sharedInstance] downloadEventDataCompletionHandler:^(BOOL success) {
        
        if (success) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (!_updateAtStartUp) {
                    [self.refreshControl endRefreshing];
                }
                
                if (self.refreshControl == nil) {
                    [self addRefreshControl];
                }
                
                _isLoadingData = NO;
                _updateAtStartUp = NO;
                
                [self performFetch];
            });
            
        } else {
            NSLog(@"Failed Download.");
        }
    }];
}

- (void)addRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(updateEventData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
}

- (void)filterEventsForSearchString:(NSString *)searchString
{
    NSArray *keysToSearch = @[@"title",@"category",@"location",@"startDateString"];
    [_filteredEventArray removeAllObjects];
    
    NSArray *searchWords = [searchString componentsSeparatedByString:@" "];
    NSMutableArray *predicateArray = [NSMutableArray array];
    
    for (NSString *searchWord in searchWords) {
        if ([searchWord length] > 0) {
            NSString *predicateBuilder = [[NSString alloc] init];
            
            for (NSString *key in keysToSearch) {
                NSString *escapedSearchWord = [searchWord stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
                
                if (key != [keysToSearch lastObject]) {
                    predicateBuilder = [predicateBuilder stringByAppendingString:[NSString stringWithFormat:@"SELF.%@ CONTAINS[c] '%@' OR ", key, escapedSearchWord]];
                } else {
                    predicateBuilder = [predicateBuilder stringByAppendingString:[NSString stringWithFormat:@"SELF.%@ CONTAINS[c] '%@'", key, escapedSearchWord]];
                }
            }
            [predicateArray addObject:[NSPredicate predicateWithFormat:predicateBuilder]];
        }
    }
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicateArray];
    _filteredEventArray = [NSMutableArray arrayWithArray:[[self.fetchedResultsController fetchedObjects] filteredArrayUsingPredicate:predicate]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        return [_filteredEventArray count];
        
    } else if (_fetchedResultsController != nil) {
        
        if ([self.fetchedResultsController.fetchedObjects count] > 0) {
            
            return [self.fetchedResultsController.fetchedObjects count];
        } else {
            return 1;
        }
        
    } else {
        
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_updateAtStartUp) {
        static NSString *CellIdentifier = @"LoadingCell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (indexPath.row == 0) {
            /*UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            activityIndicator.center = CGPointMake((roundf(cell.bounds.size.width) / 2.0f + 46.0f), (roundf(cell.bounds.size.height) / 2.0f));
            [activityIndicator startAnimating];
            [cell addSubview:activityIndicator];*/
            
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:102];
            [activityIndicator startAnimating];
            
            UILabel *loadingLabel = (UILabel *)[cell viewWithTag:101];
            loadingLabel.text = @"Loading...";
        }
        
        return cell;
        
    } else if (tableView == self.searchDisplayController.searchResultsTableView || [self.fetchedResultsController.fetchedObjects count] > 0) {
        
        static NSString *CellIdentifier = @"EventCell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        Event *event;
        
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            event = [_filteredEventArray objectAtIndex:indexPath.row];
        } else if ([self.fetchedResultsController.fetchedObjects count] > 0) {
            event = [self.fetchedResultsController objectAtIndexPath:indexPath];
        }
        
        cell.textLabel.text = event.title;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        //[dateFormatter setDateFormat:@"EEE, MMM d, yyyy"];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        
        NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        NSString *dateString;
        if (event.startDate != nil) {
            dateString = [NSString stringWithFormat:@"%@ %@", [dateFormatter stringFromDate:event.startDate], [timeFormatter stringFromDate:event.startDate]];
        } else {
            dateString = @"TBA";
        }
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ in %@", dateString, event.location];
        
        return cell;
        
    } else {
        static NSString *CellIdentifier = @"NoResultsCell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (indexPath.row == 0 && !_isLoadingData) {
            cell.textLabel.text = @"No Results";
        }
        return cell;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterEventsForSearchString:searchString];
    
    // YES if the display controller should reload the data in its table view, otherwise NO.
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    // YES if the display controller should reload the data in its table view, otherwise NO.
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    //tableView.backgroundView = _backgroundView;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(localStartDate >= %@)", [NSDate date]];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    [fetchRequest setFetchBatchSize:20];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = nil;
    
    return _fetchedResultsController;
}

- (void)performFetch
{
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"NSFetchedResultsController performFetch Error: %@", [error localizedDescription]);
        return;
    }
    
    [self.tableView reloadData];
}

@end
