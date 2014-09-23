//
//  EventManager.m
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import "EventManager.h"
#import "CalendarManager.h"
#import "Constants.h"
#import "Event.h"
#import "RssFeedParser.h"

@interface EventManager()
{
    NSURLSession *_session;
    NSInteger _networkActivityCount;
    BOOL _eventTimeChangeOccurred;
}

@end

@implementation EventManager

+ (EventManager *)sharedInstance
{
    static EventManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[EventManager alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
        
        _networkActivityCount = 0;
    }
    
    return self;
}

- (void)downloadEventDataCompletionHandler:(void (^)(BOOL success))completionHandler
{
    [self incrementNetworkActivityCount];
    
    NSURL *url = MSU_RSS_URL;
    
    NSURLSessionDataTask *dataTask = [_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            
            //NSString *rawDataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //NSLog(@"rawDataString: %@", rawDataString);
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if (httpResponse.statusCode == 200) {
                
                RssFeedParser *parser = [[RssFeedParser alloc] init];
                NSArray *eventsDictionaries = [parser itemsFromRssFeedXmlData:data];
                
                if (eventsDictionaries) {
                    
                    // NSArray calendarEventsData holds information of events that are saved to the calendar so that the model
                    // can reflect this status after data delete and update.
                    NSArray *calendarEventsData = [self arrayOfCalendarEventsData];
                    
                    [self deleteAllData];
                    _eventTimeChangeOccurred = NO;  // Initialize to 'NO' at the beginning of update.
                    
                    [[CalendarManager sharedInstance] correctForEventsRemovedUsingCalendarApp:calendarEventsData completionHandler:^(NSArray *calendarCorrections, BOOL success) {
                        
                        [self updateModelWithEventsDictionaries:eventsDictionaries calendarCorrections:calendarCorrections];
                        
                        if (completionHandler != nil) {
                            completionHandler(YES);
                        }
                    }];
                    
                } else {
                    if (completionHandler != nil) {
                        completionHandler(NO);
                    }
                }
                
            } else {
                NSLog(@"Unable To Download Event Data. HTTP Response Status Code: %li", (long)httpResponse.statusCode);
                if (completionHandler != nil) {
                    completionHandler(NO);
                }
            }
        } else {
            NSLog(@"Unable To Download Event Data. Connection Error: %@", error);
            if (completionHandler != nil) {
                completionHandler(NO);
            }
        }
        
        [self decrementNetworkActivityCount];
    }];
    
    [dataTask resume];
}

- (void)incrementNetworkActivityCount
{
    if (_networkActivityCount == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ATNetworkActivityHasStarted" object:self userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
    }
    
    _networkActivityCount++;
}

- (void)decrementNetworkActivityCount
{
    _networkActivityCount--;
    
    if (_networkActivityCount < 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ATNetworkActivityHasEnded" object:self userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
    }
}

- (void)updateModelWithEventsDictionaries:(NSArray *)eventsDictionaries calendarCorrections:(NSArray *)calendarCorrections
{
    BOOL foundCategory;
    NSMutableArray *dictionaryArrayForEventDateCorrection = [[NSMutableArray alloc] init];
    
    for (NSMutableDictionary *eventDictionary in eventsDictionaries)
    {
        Event *event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
        
        event.title = [eventDictionary objectForKey:@"title"];
        event.descrip = [eventDictionary objectForKey:@"description"];
        event.link = [eventDictionary objectForKey:@"link"];
        event.gameId = [eventDictionary objectForKey:@"ev:gameid"];
        event.location = [eventDictionary objectForKey:@"ev:location"];
        if ([event.location length] < 1) {
            event.location = @"TBA";
        }
        event.teamLogoUrl = [eventDictionary objectForKey:@"s:teamlogo"];
        event.opponentLogoUrl = [eventDictionary objectForKey:@"s:opponentlogo"];
        
        event.startDate = [self formattedDateFromString:[eventDictionary objectForKey:@"ev:startdate"]];
        event.endDate = [self formattedDateFromString:[eventDictionary objectForKey:@"ev:enddate"]];
        event.localStartDate = [self formattedDateFromString:[eventDictionary objectForKey:@"s:localstartdate"]];
        event.localEndDate = [self formattedDateFromString:[eventDictionary objectForKey:@"s:localstartdate"]];
        
        // Determine if event is home or away.
        if ([[eventDictionary objectForKey:@"ev:location"] isEqualToString:kHomeCityStateAbv] || [[eventDictionary objectForKey:@"ev:location"] isEqualToString:kHomeCityStateFull]) {
            event.isHomeEvent = @"YES";
        } else {
            event.isHomeEvent = @"NO";
        }
        
        // Find category of event by looking in the title.
        foundCategory = NO;
        for (NSString *category in SPORTS_CATEGORIES) {
            
            if([event.title rangeOfString:category].location != NSNotFound)
            {
                event.category = category;
                foundCategory = YES;
                break;
            }
        }
        if(!foundCategory) {
            
            event.category = @"NCAA";
            NSLog(@"title: %@, category: %@", event.title, event.category);
        }
        
        // Convert the start date to a string (event.startDateString) for searching date.
        NSDateFormatter *formatterFullStyle = [[NSDateFormatter alloc] init];
        [formatterFullStyle setDateStyle:NSDateFormatterFullStyle];
        NSDateFormatter *formatterShortStyle = [[NSDateFormatter alloc] init];
        [formatterShortStyle setDateStyle:NSDateFormatterShortStyle];
        event.startDateString = [NSString stringWithFormat:@"%@ %@", [formatterFullStyle stringFromDate:event.startDate], [formatterShortStyle stringFromDate:event.startDate]];
        
        // Synchronize DataModel and iPhone calendar app.
        if (calendarCorrections != nil && [calendarCorrections count] > 0) {
            
            for (NSDictionary *calendarInfoDictionary in calendarCorrections) {
                
                if ([event.gameId isEqualToString:[calendarInfoDictionary objectForKey:@"gameId"]]) {
                    event.isInCalendar = @"YES";
                    event.eventIdentifier = [calendarInfoDictionary objectForKey:@"eventIdentifier"];
                    
                    // Check for startDate and endDate change.
                    if (![event.startDate isEqualToDate:[calendarInfoDictionary objectForKey:@"startDate"]]) {
                        _eventTimeChangeOccurred = YES;
                        NSLog(@"startDate changed");
                    }
                    if (![event.endDate isEqualToDate:[calendarInfoDictionary objectForKey:@"endDate"]]) {
                        _eventTimeChangeOccurred = YES;
                        NSLog(@"endDate changed");
                    }
                    break;
                    
                } else {
                    event.isInCalendar = @"NO";
                    event.eventIdentifier = @"NONE";
                }
            }
            if (_eventTimeChangeOccurred) {
                NSMutableDictionary *dateChangedDictionary = [[NSMutableDictionary alloc] init];
                [dateChangedDictionary setObject:event.eventIdentifier forKey:@"eventIdentifier"];
                [dateChangedDictionary setObject:event.startDate forKey:@"startDate"];
                [dateChangedDictionary setObject:event.endDate forKey:@"endDate"];
                [dictionaryArrayForEventDateCorrection addObject:dateChangedDictionary];
            }
        } else {
            event.isInCalendar = @"NO";
            event.eventIdentifier = @"NONE";
        }
    }
    
    if (_eventTimeChangeOccurred) {
        [[CalendarManager sharedInstance] correctChangedDatesForEvents:dictionaryArrayForEventDateCorrection completionHandler:nil];
    }
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        FATAL_CORE_DATA_ERROR(error);
        return;
    }
    
    [self saveRefreshTime:[NSDate date]];
}

- (void)deleteAllData
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext]];
    [request setIncludesPropertyValues:NO];
    
    NSError *fetchError;
    NSArray *managedObjects = [self.managedObjectContext executeFetchRequest:request error:&fetchError];
    
    for (NSManagedObject *managedObject in managedObjects) {
        [self.managedObjectContext deleteObject:managedObject];
    }
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        FATAL_CORE_DATA_ERROR(error);
        return;
    }
}

- (NSArray *)arrayOfCalendarEventsData
{
    NSMutableArray *calendarEventsData = [[NSMutableArray alloc] init];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"SELF.isInCalendar CONTAINS[c] 'YES'"]];
    [request setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error;
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (!error) {
        
        for (Event *event in fetchResults) {
            NSMutableDictionary *calendarInfo = [[NSMutableDictionary alloc] init];
            [calendarInfo setObject:event.gameId forKey:@"gameId"];
            [calendarInfo setObject:event.eventIdentifier forKey:@"eventIdentifier"];
            [calendarInfo setObject:event.startDate forKey:@"startDate"];
            [calendarInfo setObject:event.endDate forKey:@"endDate"];
            [calendarEventsData addObject:calendarInfo];
        }
    }
    
    return calendarEventsData;
}

- (NSDate *)formattedDateFromString:(NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    // Try for date in the format: 2012-02-03T16:00:00.0000000
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    if ([dateFormatter dateFromString:dateString]) {
        return [dateFormatter dateFromString:dateString];
    }
    
    // Try for date in the format: 2012-02-03T16:00:00.0000000Z
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    if ([dateFormatter dateFromString:dateString]) {
        return [dateFormatter dateFromString:dateString];
    }
    
    // Try for date in the format: 2012-02-03
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    if ([dateFormatter dateFromString:dateString]) {
        return [dateFormatter dateFromString:dateString];
    }
    
    // Else, none of the formats applied.
    NSLog(@"Unable to convert string to date using formatter.");
    return nil;
}

-(void)saveRefreshTime:(NSDate *)refreshTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"];
        
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[formatter stringFromDate:refreshTime] forKey:@"eventsRefreshTime"];
    [defaults synchronize];
}

@end
