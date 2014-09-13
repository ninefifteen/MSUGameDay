//
//  RssFeedParser.h
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RssFeedParser : NSObject

- (NSArray *)itemsFromRssFeedXmlData:(NSData *)data;

@end
