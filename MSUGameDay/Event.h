//
//  Event.h
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Event : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * teamLogoUrl;
@property (nonatomic, retain) NSString * startDateString;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSString * opponentLogoUrl;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSDate * localStartDate;
@property (nonatomic, retain) NSDate * localEndDate;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * isInCalendar;
@property (nonatomic, retain) NSString * isHomeEvent;
@property (nonatomic, retain) NSString * gameId;
@property (nonatomic, retain) NSString * eventIdentifier;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSString * descrip;
@property (nonatomic, retain) NSString * category;

@end
