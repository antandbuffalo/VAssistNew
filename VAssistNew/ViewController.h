//
//  ViewController.h
//  VAssistNew
//
//  Created by Jeyabalaji T M on 16/11/16.
//  Copyright © 2016 Ant and Buffalo. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;

@interface ViewController : UIViewController <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

