//
//  CalendarManager.h
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>

@interface CalendarManager : NSObject

+ (CalendarManager *)sharedInstance;

- (void)addEventToCalendarWithTitle:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate completionHandler:(void (^)(BOOL success))completionHandler;
- (void)removeEventFromCalendarWithEventIdentifier:(NSString *)eventIdentifier completionHandler:(void (^)(BOOL success))completionHandler;
- (void)correctForEventsRemovedUsingCalendarApp:(NSArray *)eventIdentifiers completionHandler:(void (^)(NSArray *calendarCorrections, BOOL success))completionHandler;
- (void)correctChangedDatesForEvents:(NSMutableArray *)dictionaryArray completionHandler:(void (^)(BOOL success))completionHandler;

@end
