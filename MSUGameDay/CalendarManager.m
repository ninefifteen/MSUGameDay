//
//  CalendarManager.m
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import "CalendarManager.h"

@implementation CalendarManager

+ (CalendarManager *)sharedInstance
{
    static CalendarManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[CalendarManager alloc] init];
    });
    
    return _sharedInstance;
}

- (void)addEventToCalendarWithTitle:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate completionHandler:(void (^)(BOOL success))completionHandler
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
        
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            
        if (error) {
            
            if (completionHandler != nil) {
                completionHandler(NO);
            }
            
            [self showCalendarErrorMessage:@"Unable To Add Event To Calendar." error:error];
            
        } else if (!granted) {
            
            if (completionHandler != nil) {
                completionHandler(NO);
            }
            
            [self showCalendarAccessNotEnabledMessage];
            
        } else {
            
            EKEvent *ekEvent = [EKEvent eventWithEventStore:eventStore];
            ekEvent.title = title;
            ekEvent.startDate = startDate;
            ekEvent.endDate = endDate;
            
            // Set the reminder alarms for the event.
            NSMutableArray *alarmsArray = [NSMutableArray array];
            EKAlarm *firstAlarm = [EKAlarm alarmWithRelativeOffset:-86400]; // 1 day before event.
            EKAlarm *secondAlarm = [EKAlarm alarmWithRelativeOffset:-3600]; // 1 hour before event.
            [alarmsArray addObject:firstAlarm];
            [alarmsArray addObject:secondAlarm];
            ekEvent.alarms = alarmsArray;
            
            [ekEvent setCalendar:[eventStore defaultCalendarForNewEvents]];
            
            NSError *saveEventError;
            [eventStore saveEvent:ekEvent span:EKSpanThisEvent error:&saveEventError];
            
            if (!saveEventError) {
                
                if (completionHandler != nil) {
                    completionHandler(YES);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Event Saved To Calendar!"
                                                                         message:nil delegate:nil
                                                               cancelButtonTitle:@"OK"
                                                               otherButtonTitles:nil, nil];
                    [alertView show];
                    [self performSelector:@selector(dismissAlertView:) withObject:alertView afterDelay:1.5f];
                });
                
            } else {
                
                if (completionHandler != nil) {
                    completionHandler(NO);
                }
                
                [self showCalendarErrorMessage:@"Unable To Add Event To Calendar." error:saveEventError];
            }
        }
    }];
}

- (void)removeEventFromCalendarWithEventIdentifier:(NSString *)eventIdentifier completionHandler:(void (^)(BOOL success))completionHandler
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
        
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            
        if (error) {
            
            if (completionHandler != nil) {
                completionHandler(NO);
            }
            
            [self showCalendarErrorMessage:@"Unable To Remove Event From Calendar." error:error];
            
        } else if (!granted) {
            
            if (completionHandler != nil) {
                completionHandler(NO);
            }
            
            [self showCalendarAccessNotEnabledMessage];
            
        } else {
            
            EKEvent *ekEvent = [eventStore eventWithIdentifier:eventIdentifier];
            
            NSError *removeEventError;
            [eventStore removeEvent:ekEvent span:EKSpanThisEvent error:&removeEventError];
            
            if (!removeEventError) {
                
                if (completionHandler != nil) {
                    completionHandler(YES);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Event Removed From Calendar."
                                                                         message:nil
                                                                        delegate:nil
                                                               cancelButtonTitle:nil
                                                               otherButtonTitles:nil, nil];
                    [alertView show];
                    [self performSelector:@selector(dismissAlertView:) withObject:alertView afterDelay:1.5f];
                });
                
            } else {
                
                if (completionHandler != nil) {
                    completionHandler(NO);
                }
                
                [self showCalendarErrorMessage:@"Unable To Remove Event From Calendar." error:removeEventError];
            }
        }
    }];
}

- (void)correctForEventsRemovedUsingCalendarApp:(NSArray *)eventIdentifiers completionHandler:(void (^)(NSArray *calendarCorrections, BOOL success))completionHandler
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        
        if (error) {
            
            if (completionHandler != nil) {
                completionHandler(nil, NO);
            }
            
            NSLog(@"Error correcting for events removed using Calendar app. Error: %@", [error localizedDescription]);
            
        } else if (!granted) {
            
            if (completionHandler != nil) {
                completionHandler(nil, NO);
            }
            
            NSLog(@"Calendar access not enabled");
            
        } else {
            
            NSMutableArray *calendarCorrections = [[NSMutableArray alloc] init];
            
            for (NSDictionary *dictionary in eventIdentifiers) {
                
                EKEvent *ekEvent = [eventStore eventWithIdentifier:[dictionary objectForKey:@"eventIdentifier"]];
                
                if (ekEvent != nil) {
                    [calendarCorrections addObject:dictionary];
                }
            }
            
            if (completionHandler != nil) {
                completionHandler(calendarCorrections, YES);
            }
        }
    }];
}

- (void)correctChangedDatesForEvents:(NSArray *)dictionaryArray completionHandler:(void (^)(BOOL success))completionHandler
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        
        if (error) {
            
            if (completionHandler != nil) {
                completionHandler(NO);
            }
            
            NSLog(@"Error correcting changed dates for events. Error: %@", [error localizedDescription]);
            
        } else if (!granted) {
            
            if (completionHandler != nil) {
                completionHandler(NO);
            }
            
            NSLog(@"Calendar access not enabled");
            
        } else {
            
            for (NSDictionary *dictionary in dictionaryArray) {
                
                EKEvent *ekEvent = [eventStore eventWithIdentifier:[dictionary objectForKey:@"eventIdentifier"]];
                
                ekEvent.startDate = [dictionary objectForKey:@"startDate"];
                ekEvent.endDate = [dictionary objectForKey:@"endDate"];
                
                NSError *errorSaveEvent;
                [eventStore saveEvent:ekEvent span:EKSpanThisEvent error:&errorSaveEvent];
                
                if (!errorSaveEvent) {
                    NSLog(@"Unable to change date for event. Error: %@", [error localizedDescription]);
                }
            }
            
            if (completionHandler != nil) {
                completionHandler(YES);
            }
        }
    }];
}

- (void)showCalendarAccessNotEnabledMessage
{
    NSLog(@"Calendar access not enabled");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Calendar Access Required"
                                                             message:@"Please enable access to your calendar in Settings"
                                                            delegate:nil cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil, nil];
        [alertView show];
    });
}

- (void)showCalendarErrorMessage:(NSString *)message error:(NSError *)error
{
    NSLog(@"%@ Error: %@", message, [error localizedDescription]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:message
                                                            delegate:nil cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil, nil];
        [alertView show];
    });
}

- (void)dismissAlertView:(UIAlertView *)alertView
{
    [alertView dismissWithClickedButtonIndex:-1 animated:YES];
}

@end
