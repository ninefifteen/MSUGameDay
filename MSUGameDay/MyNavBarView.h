//
//  MyNavBarView.h
//  MSUGameDay
//
//  Created by Shawn Seals on 9/13/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SSRollingButtonScrollView;

@interface MyNavBarView : UIView

@property (weak, nonatomic) IBOutlet UIButton *leftScrollButton;
@property (weak, nonatomic) IBOutlet UIButton *rightScrollButton;
@property (weak, nonatomic) IBOutlet SSRollingButtonScrollView *rollingButtonScrollView;

@end
