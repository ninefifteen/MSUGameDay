//
//  MasterViewController.h
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class DetailViewController;
@class SSRollingButtonScrollView;

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet SSRollingButtonScrollView *rollingButtonScrollView;
@property (weak, nonatomic) IBOutlet UIView *customNavBarView;

- (IBAction)leftScrollButtonPressed:(UIButton *)sender;
- (IBAction)rightScrollButtonPressed:(UIButton *)sender;

@end

