//
//  RssFeedParser.m
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import "RssFeedParser.h"

@interface RssFeedParser() <NSXMLParserDelegate>
{
    NSXMLParser *_xmlParser;
    NSError *_parseError;
    
    NSMutableArray *_itemsArray;
    NSMutableDictionary *_itemDictionary;
    NSMutableString *_currentElementString;
    NSMutableArray *_informationDictionaryOfCalendarEventsArray;
    
    BOOL _accumulatingCurrentElementString;
}

@end

@implementation RssFeedParser

- (id)init
{
    self = [super init];
    
    if (self) {
        _itemsArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSArray *)itemsFromRssFeedXmlData:(NSData *)data
{
    _xmlParser = [[NSXMLParser alloc] initWithData:data];
    
    [_xmlParser setDelegate:self];
    [_xmlParser parse];
    
    if (!_parseError) {
        return _itemsArray;
    } else {
        NSLog(@"RSS Feed Parser Error: %@", [_parseError localizedDescription]);
        return nil;
    }
}

#pragma mark - NSXMLParserDelegate

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kItemElementName = @"item";
static NSString * const kTitleElementName = @"title";
static NSString * const kDescriptionElementName = @"description";
static NSString * const kGuidElementName = @"guid";
static NSString * const kLinkElementName = @"link";
static NSString * const kGameIdElementName = @"ev:gameid";
static NSString * const kEventLocationElementName = @"ev:location";
static NSString * const kTeamLogoUrlElementName = @"s:teamlogo";
static NSString * const kOpponentLogoUrlElementName = @"s:opponentlogo";
static NSString * const kEventStartDateElementName = @"ev:startdate";
static NSString * const kEventEndDateElementName = @"ev:enddate";
static NSString * const kLocalStartDateElementName = @"s:localstartdate";
static NSString * const kLocalEndDateElementName = @"s:localenddate";

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:kItemElementName]) {
        [_itemsArray addObject:_itemDictionary];
    } else if ([elementName isEqualToString:kTitleElementName]) {
        [_itemDictionary setObject:[self stripDateFromRawTitle:_currentElementString] forKey:@"title"];
    } else if ([elementName isEqualToString:kDescriptionElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"description"];
    } else if ([elementName isEqualToString:kGuidElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"guid"];
    } else if ([elementName isEqualToString:kLinkElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"link"];
    } else if ([elementName isEqualToString:kGameIdElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"ev:gameid"];
    } else if ([elementName isEqualToString:kEventLocationElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"ev:location"];
    } else if ([elementName isEqualToString:kTeamLogoUrlElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"s:teamlogo"];
    } else if ([elementName isEqualToString:kOpponentLogoUrlElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"s:opponentlogo"];
    } else if ([elementName isEqualToString:kEventStartDateElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"ev:startdate"];
    } else if ([elementName isEqualToString:kEventEndDateElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"ev:enddate"];
    } else if ([elementName isEqualToString:kLocalStartDateElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"s:localstartdate"];
    } else if ([elementName isEqualToString:kLocalEndDateElementName]) {
        [_itemDictionary setObject:_currentElementString forKey:@"s:localenddate"];
    }
}

- (NSString *)stripDateFromRawTitle:(NSString *)rawTitle
{
    NSInteger index = 0;
    
    // Used to find space characters in string.
    NSMutableCharacterSet *space = [NSMutableCharacterSet characterSetWithCharactersInString:@" "];
    
    // Check for date at beginning of title.
    if ([rawTitle length] > 5) {
        // If the date is in the format M/D.
        if (isdigit([rawTitle characterAtIndex:0]) &&
            [rawTitle characterAtIndex:1] == '/' &&
            isdigit([rawTitle characterAtIndex:2]) &&
            [space characterIsMember:[rawTitle characterAtIndex:3]]) {
            
            index = 4;
        }
        // If the date is in the format M/DD.
        else if (isdigit([rawTitle characterAtIndex:0]) &&
                 [rawTitle characterAtIndex:1] == '/' &&
                 isdigit([rawTitle characterAtIndex:2]) &&
                 isdigit([rawTitle characterAtIndex:3]) &&
                 [space characterIsMember:[rawTitle characterAtIndex:4]]) {
            
            index = 5;
        }
        // If the date is in the format MM/D.
        else if (isdigit([rawTitle characterAtIndex:0]) &&
                 isdigit([rawTitle characterAtIndex:1]) &&
                 [rawTitle characterAtIndex:2] == '/' &&
                 isdigit([rawTitle characterAtIndex:3]) &&
                 [space characterIsMember:[rawTitle characterAtIndex:4]]) {
            
            index = 5;
        }
        // If the date is in the format MM/DD.
        else if (isdigit([rawTitle characterAtIndex:0]) &&
                 isdigit([rawTitle characterAtIndex:1]) &&
                 [rawTitle characterAtIndex:2] == '/' &&
                 isdigit([rawTitle characterAtIndex:3]) &&
                 isdigit([rawTitle characterAtIndex:4]) &&
                 [space characterIsMember:[rawTitle characterAtIndex:5]]) {
            
            index = 6;
        }
        // Else there is no date at the beginning of the title string.
    }
    
    if ([rawTitle length] > 13) {
        // If the title contains the time in the format H:MM AP.
        if ((isdigit([rawTitle characterAtIndex:index]) &&
             ([rawTitle characterAtIndex:(index + 1)] == ':')) &&
            (isdigit([rawTitle characterAtIndex:(index + 2)]))) {
            
            index = index + 8;  // Index of character after space after time
        }
        // Else If the title contains the time in the format HH:MM AP.
        else if (isdigit([rawTitle characterAtIndex:index]) &&
                 (isdigit([rawTitle characterAtIndex:(index + 1)])) &&
                 ([rawTitle characterAtIndex:(index + 2)] == ':') &&
                 (isdigit([rawTitle characterAtIndex:(index + 3)]))) {
            
            index = index + 9;  // Index of character after space after time
        }
        // Else the title does not contain the time, so do nothing.
    }
    
    // The title element contains the title, date, and location in the following format:
    // <title>1/31 7:30 PM [W] Men's Basketball at Abilene Christian<title/>
    // Use the scanner along with the index calculated above to scan only the title.
    NSScanner *scanner = [NSScanner scannerWithString:rawTitle];
    [scanner setScanLocation:index];
    
    return [[scanner string] substringFromIndex:[scanner scanLocation]];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    _currentElementString = [[NSMutableString alloc] init];
    
    if ([elementName isEqualToString:kItemElementName]) {
        
        _itemDictionary = [[NSMutableDictionary alloc] init];
        
    } else if ([elementName isEqualToString:kTitleElementName] ||
               [elementName isEqualToString:kDescriptionElementName] ||
               [elementName isEqualToString:kGuidElementName] ||
               [elementName isEqualToString:kLinkElementName] ||
               [elementName isEqualToString:kGameIdElementName] ||
               [elementName isEqualToString:kEventLocationElementName] ||
               [elementName isEqualToString:kTeamLogoUrlElementName] ||
               [elementName isEqualToString:kOpponentLogoUrlElementName] ||
               [elementName isEqualToString:kEventStartDateElementName] ||
               [elementName isEqualToString:kEventEndDateElementName] ||
               [elementName isEqualToString:kLocalStartDateElementName] ||
               [elementName isEqualToString:kLocalEndDateElementName]) {
        
        _accumulatingCurrentElementString = YES;
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // If the current element is one whose content we care about, append 'string' to the property that holds the content of the current element.
    if (_accumulatingCurrentElementString) {
        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [_currentElementString appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    _parseError = parseError;
}

@end
