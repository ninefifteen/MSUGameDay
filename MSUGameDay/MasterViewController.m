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

@interface MasterViewController () <UISearchResultsUpdating, SSRollingButtonScrollViewDelegate, UISplitViewControllerDelegate>

@property (nonatomic) BOOL isLoadingData;
@property (nonatomic) BOOL updateAtStartUp;
@property (nonatomic) CGFloat navBarWidth;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSMutableArray *filteredEvents;

@property (strong, nonatomic) UIView *tableBackgroundView;
@property (strong, nonatomic) UIView *searchTableBackgroundView;

@property (strong, nonatomic) UIButton *currentCenterButton;

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
    
    self.title = @"Events";
    
    self.navBarWidth = 0.0;
    [self configureCustomNavBarView];
    [self configureSearchController];
    [self configureBackgrounds];
    
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
        [self configureRefreshControl];
    }
}

- (void)configureCustomNavBarView
{
    NSArray *sportsCategoriesForButtons = SPORTS_CATEGORIES_BUTTONS;
    
    self.rollingButtonScrollView.fixedButtonWidth = 88.0f;
    self.rollingButtonScrollView.spacingBetweenButtons = 2.0f;
    self.rollingButtonScrollView.buttonCenterFont = [UIFont boldSystemFontOfSize:18];
    self.rollingButtonScrollView.buttonNotCenterFont = [UIFont systemFontOfSize:13];
    self.rollingButtonScrollView.notCenterButtonTextColor = [UIColor grayColor];
    self.rollingButtonScrollView.centerButtonTextColor = MSU_GOLD_COLOR;
    self.rollingButtonScrollView.stopOnCenter = YES;
    self.rollingButtonScrollView.ssRollingButtonScrollViewDelegate = self;
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

- (void)configureBackgrounds
{
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableBackgroundView = [[[NSBundle mainBundle] loadNibNamed:@"TableBackgroundView" owner:self options:nil] objectAtIndex:0];
    self.tableView.backgroundView = self.tableBackgroundView;
    
    UITableView *searchTable = ((UITableViewController *)self.searchController.searchResultsController).tableView;
    searchTable.backgroundColor = [UIColor clearColor];
    self.searchTableBackgroundView = [[[NSBundle mainBundle] loadNibNamed:@"TableBackgroundView" owner:self options:nil] objectAtIndex:0];
    searchTable.backgroundView = self.searchTableBackgroundView;
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
        
        Event *event;
        
        UITableView *searchTableView = ((UITableViewController *)self.searchController.searchResultsController).tableView;
        
        if (sender == [searchTableView cellForRowAtIndexPath:[searchTableView indexPathForSelectedRow]]) {
            
            UITableView *tableView = ((UITableViewController *)self.searchController.searchResultsController).tableView;
            NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
            event = [self.filteredEvents objectAtIndex:indexPath.row];
            
        } else {
            
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            event = [self.fetchedResultsController objectAtIndexPath:indexPath];
        }
        
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.event = event;
        controller.managedObjectContext = self.managedObjectContext;
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
        
        if ([self.filteredEvents count] > 0) {
            return [self.filteredEvents count];
        } else {
            return 1;
        }
        
        
    } else if (_fetchedResultsController != nil) {
        
        if ([self.fetchedResultsController.fetchedObjects count] > 0) {
            return [self.fetchedResultsController.fetchedObjects count];
        } else if (self.updateAtStartUp) {
            return 1;
        } else if (!self.isLoadingData) {
            return 1;
        } else {
            return 0;
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
        cell.backgroundColor = [UIColor clearColor];
        return cell;
        
    } else if (tableView == ((UITableViewController *)self.searchController.searchResultsController).tableView) {
        
        if ([self.filteredEvents count] > 0) {
            
            static NSString *CellIdentifier = @"EventCell";
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            Event *event = [self.filteredEvents objectAtIndex:indexPath.row];
            return [self configureCell:cell forEvent:event];
            
        } else {
            
            static NSString *CellIdentifier = @"NoResultsCell";
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            if (indexPath.row == 0 && !self.isLoadingData) {
                cell.textLabel.text = @"No Results";
            }
            cell.backgroundColor = [UIColor clearColor];
            return cell;
        }
        
    } else {
        
        if ([self.fetchedResultsController.fetchedObjects count] > 0) {
            
            static NSString *CellIdentifier = @"EventCell";
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
            return [self configureCell:cell forEvent:event];
            
        } else {
            
            static NSString *CellIdentifier = @"NoResultsCell";
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            if (indexPath.row == 0 && !self.isLoadingData) {
                cell.textLabel.text = @"No Results";
            }
            cell.backgroundColor = [UIColor clearColor];
            return cell;
        }
    }
}

- (UITableViewCell *)configureCell:(UITableViewCell *)cell forEvent:(Event *)event
{
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
    
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    
    if (self.currentCenterButton == nil || [self.currentCenterButton.titleLabel.text isEqualToString:@"All Sports"]) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(localStartDate >= %@)", [[NSDate date] dateByAddingTimeInterval:-86400 * 2]];
        [fetchRequest setPredicate:predicate];
        
    } else {
        
        NSString *category;
        if ([self.currentCenterButton.titleLabel.text isEqualToString:@"X-Country"]) {
            category = @"Country";
        } else {
            category = self.currentCenterButton.titleLabel.text;
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category CONTAINS [c] %@ AND (localStartDate >= %@)", category, [[NSDate date] dateByAddingTimeInterval:-86400 * 2]];
        [fetchRequest setPredicate:predicate];
    }
    
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

- (IBAction)leftScrollButtonPressed:(UIButton *)sender
{
    [self.rollingButtonScrollView advanceRollingButtonScrollViewIndexBy:-1];
}

- (IBAction)rightScrollButtonPressed:(UIButton *)sender
{
    [self.rollingButtonScrollView advanceRollingButtonScrollViewIndexBy:1];
}

#pragma mark - SSRollingButtonScrollViewDelegate

- (void)rollingScrollViewButtonIsInCenter:(UIButton *)button ssRollingButtonScrollView:(SSRollingButtonScrollView *)rollingButtonScrollView
{
    self.currentCenterButton = button;
    
    _fetchedResultsController = nil;
    [self.tableView reloadData];
    if (!_isLoadingData) {
        [self performFetch];
    }
}

- (void)rollingScrollViewButtonPushed:(UIButton *)button ssRollingButtonScrollView:(SSRollingButtonScrollView *)rollingButtonScrollView
{
    self.currentCenterButton = button;
    
    _fetchedResultsController = nil;
    [self.tableView reloadData];
    if (!_isLoadingData) {
        [self performFetch];
    }
}

@end
