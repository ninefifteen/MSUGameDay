//
//  DetailViewController.m
//  MSUGameDay
//
//  Created by Shawn Seals on 9/12/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import "DetailViewController.h"
#import "Event.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)addEventToCalendar:(Event *)event
{
    //
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.event) {
        return 4;
    } else {
        return 0;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
            
        case 0:
            return 1;
            break;
            
        case 1:
            if ([HOST_TYPE_CATEGORIES containsObject:self.event.category]) {
                return 1;
            } else {
                return 2;
            }
            return 2;
            break;
            
        case 2:
            return 2;
            break;
            
        case 3:
            return 1;
            break;
            
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        static NSString *CellIdentifier = @"CategoryCell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.textLabel.text = self.event.category;
        return cell;
        
    } else if (indexPath.section == 1) {

        return [self configureTeamCellForRowAtIndexPath:indexPath];
        
    } else if (indexPath.section == 2) {
        
        return [self configureTimeLocationCellForRowAtIndexPath:indexPath];
        
    } else if (indexPath.section == 3) {
        
        static NSString *CellIdentifier = @"AddToCalendarCell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        return cell;
        
    } else {
        return nil;
    }
}

- (UITableViewCell *)configureTeamCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TeamCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if ([HOST_TYPE_CATEGORIES containsObject:self.event.category]) {
        
        UILabel *hostLabel = (UILabel *)[cell viewWithTag:202];
        hostLabel.text = @"Host";
        
        UILabel *hostTeamNameLabel = (UILabel *)[cell viewWithTag:203];
        hostTeamNameLabel.text = [self configureOpponentLabelTextFromTitle:self.event.title andCategory:self.event.category];
        
    } else {
        
        if (indexPath.row == 0) {
            
            UILabel *homeLabel = (UILabel *)[cell viewWithTag:202];
            homeLabel.text = @"Home";
            
            UILabel *teamNameLabel = (UILabel *)[cell viewWithTag:203];
            if ([self.event.isHomeEvent isEqualToString:@"YES"]) {
                teamNameLabel.text = kSchoolName;
            } else {
                teamNameLabel.text = [self configureOpponentLabelTextFromTitle:self.event.title andCategory:self.event.category];
            }
            
        } else {
            
            UILabel *awayLabel = (UILabel *)[cell viewWithTag:202];
            awayLabel.text = @"Away";
            
            UILabel *teamNameLabel = (UILabel *)[cell viewWithTag:203];
            if ([self.event.isHomeEvent isEqualToString:@"YES"]) {
                teamNameLabel.text = [self configureOpponentLabelTextFromTitle:self.event.title andCategory:self.event.category];
            } else {
                teamNameLabel.text = kSchoolName;
            }
        }
    }
    
    return cell;
}

- (UITableViewCell *)configureTimeLocationCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TimeLocationCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:211];
        titleLabel.text = @"Time";
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEE, MMM d, yyyy"];
        NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        NSString *dateString;
        if (self.event.startDate != nil) {
            dateString = [NSString stringWithFormat:@"%@ %@", [dateFormatter stringFromDate:self.event.startDate], [timeFormatter stringFromDate:self.event.startDate]];
        } else {
            dateString = @"TBA";
        }
        
        UILabel *timeLabel = (UILabel *)[cell viewWithTag:212];
        timeLabel.text = dateString;
        
    } else {
        
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:211];
        titleLabel.text = @"Location";
        
        UILabel *locationLabel = (UILabel *)[cell viewWithTag:212];
        locationLabel.text = self.event.location;
    }
    
    return cell;
}

- (NSString *)configureOpponentLabelTextFromTitle:(NSString *)title andCategory:(NSString *)category
{
    NSString *configuredLabel = [[NSString alloc] init];
    NSString *categoryWithSpace = [NSString stringWithFormat:@"%@ ", category];
    
    if ([title rangeOfString:@" at "].location != NSNotFound) {
        NSArray * components = [title componentsSeparatedByString:@" at "];
        configuredLabel = [[components objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ([title rangeOfString:@" vs "].location != NSNotFound) {
        NSArray * components = [title componentsSeparatedByString:@" vs "];
        configuredLabel = [[components objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ([title rangeOfString:categoryWithSpace].location != NSNotFound && ![category isEqualToString:@"NCAA"]){
        NSArray * components = [title componentsSeparatedByString:categoryWithSpace];
        configuredLabel = [[components objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else {
        configuredLabel = title;
    }
    return configuredLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 36;
    } else if (indexPath.section == 1) {
        return 66;
    } else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

@end
