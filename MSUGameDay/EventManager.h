//
//  EventManager.h
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Event;

@interface EventManager : NSObject

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

+ (EventManager *)sharedInstance;

- (void)downloadEventDataCompletionHandler:(void (^)(BOOL success))completionHandler;

@end
