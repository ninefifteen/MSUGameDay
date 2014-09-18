//
//  DetailViewController.h
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "CalendarManager.h"
#import "Event.h"

@interface DetailViewController : UITableViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Event *event;

@property (weak, nonatomic) IBOutlet UILabel *gameStartTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *gameLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *addEventToCalendarLabel;

- (void)addEventToCalendar:(Event *)event;

@end

