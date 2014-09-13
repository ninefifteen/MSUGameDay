//
//  MyNavBarView.m
//  MSUGameDay
//
//  Created by Shawn Seals on 9/13/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import "MyNavBarView.h"
#import "SSRollingButtonScrollView.h"

@implementation MyNavBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [[NSBundle mainBundle] loadNibNamed:@"MyNavBarView" owner:self options:nil][0];
    
    if (self) {
        self.frame = frame;
    }
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
