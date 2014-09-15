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
#import "SSRollingButtonScrollView.h"

@interface MasterViewController () <UISearchResultsUpdating, SSRollingButtonScrollViewDelegate>

    @property (nonatomic) BOOL isLoadingData;
    @property (nonatomic) BOOL updateAtStartUp;
    @property (nonatomic) CGFloat navBarWidth;

    @property (nonatomic, strong) UISearchController *searchController;
    @property (nonatomic, strong) NSMutableArray *filteredEvents;

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
    
    self.filteredEvents = [[NSMutableArray alloc] init];
    
    self.navBarWidth = 0.0;
    [self configureCustomNavBarView];
    [self configureSearchController];
    
    NSTimeInterval timeSinceLastUpdate = 0;
    
    // Calculate time since last update if it is not the app's first run.
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"eventsRefreshTime"] != nil) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"];
        NSDate *lastRefreshDate = [formatter dateFromString:[[NSUserDefaults standardUserDefaults] objectForKey:@"eventsRefreshTime"]];
        timeSinceLastUpdate = [[NSDate date] timeIntervalSinceDate:lastRefreshDate];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"eventsRefreshTime"] == nil || timeSinceLastUpdate > kTimeIntervalBetweenAutomaticUpdates) {
        
        self.updateAtStartUp = YES;
        [self updateEventData];
        
    } else {
        
        self.updateAtStartUp = NO;
        [self performFetch];
    }
}

- (void)configureCustomNavBarView
{
    NSArray *sportsCategoriesForButtons = @[@"Volleyball", @"All Sports", @"Basketball", @"X-Country", @"Football", @"Golf", @"Soccer", @"Softball", @"Tennis", @"Track"];
    
    self.rollingButtonScrollView.fixedButtonWidth = 88.0f;
    self.rollingButtonScrollView.spacingBetweenButtons = 2.0f;
    self.rollingButtonScrollView.buttonCenterFont = [UIFont boldSystemFontOfSize:18];
    self.rollingButtonScrollView.buttonNotCenterFont = [UIFont systemFontOfSize:13];
    self.rollingButtonScrollView.notCenterButtonTextColor = [UIColor grayColor];
    self.rollingButtonScrollView.centerButtonTextColor = MSU_GOLD_COLOR;
    self.rollingButtonScrollView.stopOnCenter = YES;
    [self.rollingButtonScrollView createButtonArrayWithButtonTitles:sportsCategoriesForButtons andLayoutStyle:SShorizontalLayout];
}

- (void)configureSearchController
{
    UITableViewController *searchResultsController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    searchResultsController.tableView.dataSource = self;
    searchResultsController.tableView.delegate = self;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    
    self.searchController.searchResultsUpdater = self;
    
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.definesPresentationContext = YES;
}

- (void)updateEventData
{
    self.isLoadingData = YES;
    
    if (_fetchedResultsController != nil) {
        _fetchedResultsController = nil;
        [self.tableView reloadData];
    }
    
    if (!self.updateAtStartUp) {
        [self.refreshControl beginRefreshing];
    }
    
    [[EventManager sharedInstance] downloadEventDataCompletionHandler:^(BOOL success) {
        
        if (success) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (!self.updateAtStartUp) {
                    [self.refreshControl endRefreshing];
                }
                
                if (self.refreshControl == nil) {
                    [self configureRefreshControl];
                }
                
                self.isLoadingData = NO;
                self.updateAtStartUp = NO;
                
                [self performFetch];
            });
            
        } else {
            NSLog(@"Failed Download.");
        }
    }];
}

- (void)configureRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(updateEventData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
}

- (void)viewWillLayoutSubviews
{
    // If the navigationBar size changes (typically due to device rotation), resize the customNavBarView with contains the rollingButtonScrollView.
    if (self.navBarWidth != self.navigationController.navigationBar.bounds.size.width) {
        
        self.navBarWidth = self.navigationController.navigationBar.bounds.size.width;
        
        //NSLog(@"navbar width: %f", self.navigationController.navigationBar.bounds.size.width);
        //NSLog(@"customNavBarView frame: %f, %f, %f, %f", self.customNavBarView.frame.origin.x, self.customNavBarView.frame.origin.y, self.customNavBarView.frame.size.width, self.customNavBarView.frame.size.height);
        //NSLog(@"rollingButtonScrollView frame: %f, %f, %f, %f", self.rollingButtonScrollView.frame.origin.x, self.rollingButtonScrollView.frame.origin.y, self.rollingButtonScrollView.frame.size.width, self.rollingButtonScrollView.frame.size.height);
        
        CGFloat newWidth = self.navigationController.navigationBar.bounds.size.width - 32.0;
        CGRect newFrame = CGRectMake(self.customNavBarView.frame.origin.x, self.customNavBarView.frame.origin.y, newWidth, self.customNavBarView.frame.size.height);
        self.customNavBarView.frame = newFrame;
    }
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
    if (tableView == ((UITableViewController *)self.searchController.searchResultsController).tableView) {
        
        return [self.filteredEvents count];
        
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
    if (self.updateAtStartUp) {
        static NSString *CellIdentifier = @"LoadingCell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (indexPath.row == 0) {
            
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:102];
            [activityIndicator startAnimating];
            
            UILabel *loadingLabel = (UILabel *)[cell viewWithTag:101];
            loadingLabel.text = @"Loading...";
        }
        
        return cell;
        
    } else if (tableView == ((UITableViewController *)self.searchController.searchResultsController).tableView || [self.fetchedResultsController.fetchedObjects count] > 0) {
        
        static NSString *CellIdentifier = @"EventCell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        Event *event;
        
        if (tableView == ((UITableViewController *)self.searchController.searchResultsController).tableView) {
            event = [self.filteredEvents objectAtIndex:indexPath.row];
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
        
        if (indexPath.row == 0 && !self.isLoadingData) {
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

#pragma mark - UISearchResultsUpdating

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = [self.searchController.searchBar text];
    
    [self filterEventsForSearchString:searchString];
    
    [((UITableViewController *)self.searchController.searchResultsController).tableView reloadData];
}

#pragma mark - Content Filtering

- (void)filterEventsForSearchString:(NSString *)searchString
{
    NSArray *keysToSearch = @[@"title",@"category",@"location",@"startDateString"];
    [self.filteredEvents removeAllObjects];
    
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
    self.filteredEvents = [NSMutableArray arrayWithArray:[[self.fetchedResultsController fetchedObjects] filteredArrayUsingPredicate:predicate]];
}

@end
