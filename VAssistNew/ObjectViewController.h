//
//  ObjectViewController.h
//  VAssist
//
//  Created by Jeyabalaji T M on 13/11/16.
//  Copyright © 2016 Ant and Buffalo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ObjectViewController : UIViewController

@property (nonatomic, strong) NSString *vcTitle;
@property (nonatomic, strong) NSMutableDictionary *objectDetails;
@property (nonatomic, copy) void (^didDismiss)(NSString *data);

@end
