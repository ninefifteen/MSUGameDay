//
//  Constants.h
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#ifndef MSUGameDay_Constants_h
#define MSUGameDay_Constants_h


#define MSU_MAROON_COLOR [UIColor colorWithRed:133/255.0f green:0/255.0f blue:56/255.0f alpha:1.0f]
#define MSU_GOLD_COLOR [UIColor colorWithRed:238/255.0f green:178/255.0f blue:17/255.0f alpha:1.0f]

#define MSU_RSS_URL [NSURL URLWithString:@"http://www.msumustangs.com/calendar.ashx/calendar.rss?"]

#define SPORTS_CATEGORIES @[@"Men's Track",@"Women's Track",@"Men's Cross Country",@"Women's Cross Country",@"Men's Basketball",@"Women's Basketball",@"Football",@"Baseball",@"Men's Golf",@"Women's Golf",@"Men's Soccer",@"Women's Soccer",@"Softball",@"Men's Tennis",@"Women's Tennis",@"Volleyball"]

#define SPORTS_CATEGORIES_BUTTONS @[@"Volleyball", @"All Sports", @"Basketball", @"X-Country", @"Football", @"Golf", @"Soccer", @"Softball", @"Tennis", @"Track"]

#define HOST_TYPE_CATEGORIES @[@"Men's Track",@"Women's Track",@"Men's Cross Country",@"Women's Cross Country",@"Men's Golf",@"Women's Golf",@"Men's Tennis",@"Women's Tennis",@"NCAA"]

static NSString * const kSchoolName = @"Midwestern State";
static NSString * const kHomeCityStateAbv = @"Wichita Falls, TX";
static NSString * const kHomeCityStateFull = @"Wichita Falls, Texas";

static int const kTimeIntervalBetweenAutomaticUpdates = 86400;   // 24 hours

extern NSString * const ManagedObjectContextSaveDidFailNotification;

#define FATAL_CORE_DATA_ERROR(__error__)\
    NSLog(@"*** Fatal error in %s:%d\n%@\n%@",\
    __FILE__, __LINE__, error, [error userInfo]);\
    [[NSNotificationCenter defaultCenter] postNotificationName:\
    ManagedObjectContextSaveDidFailNotification object:error];

#endif
