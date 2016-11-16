//
//  ViewController.m
//  VAssistNew
//
//  Created by Jeyabalaji T M on 16/11/16.
//  Copyright © 2016 Ant and Buffalo. All rights reserved.
//

#import "ViewController.h"
#import "ObjectViewController.h"
#import "Utility.h"
#import "Constants.h"
#import "Device+CoreDataProperties.h"

@interface ViewController () {
    CLBeaconRegion *beaconRegion;
    __weak IBOutlet UILabel *beaconStatus;
    int counter;
    NSMutableArray *devices;
    BOOL isModalPresented;
    ObjectViewController *objectVC;
}

@end

@implementation ViewController

- (IBAction)testButtonAction:(UIButton *)sender {
    [self presentObjectDetectedVC: nil];
}

-(NSString *)checkStatus:(NSString *)deviceName {
    //check current door status from local db and return the value
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"p_id == %@", deviceName];
    NSMutableArray *records = [Utility recordsForThePredicate:predicate forTable:@"Device"];
    if(records.count > 0) {
        Device *device = [records objectAtIndex:0];
        NSLog(@"sta - %@", device.p_status);
    }
    return nil;
}

-(void)presentObjectDetectedVC:(NSMutableDictionary *)objectDetails {
    objectVC.objectDetails = objectDetails;
    isModalPresented = YES;
    [self.navigationController presentViewController:objectVC animated:YES completion:nil];
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    NSLog(@"something - %@", beacons);
    NSLog(@"region - %@", region);
    CLBeacon *beacon;
    NSMutableDictionary *objectDetails = [[NSMutableDictionary alloc] init];
    if([region.identifier isEqualToString:VA_DOOR]) {
        objectDetails[@"type"] = VA_DOOR;
        objectDetails[@"title"] = @"Door";
        if(beacons != nil && beacons.count > 0) {
            beacon = beacons[0];
            NSString *beaconPlace = @"";
            
            BOOL openModal = NO;
            
            if(beacon.proximity == CLProximityImmediate) {
                beaconPlace = @"Immediate";
            }
            else if(beacon.proximity == CLProximityNear) {
                beaconPlace = @"Near";
                if([[self checkStatus: VA_DOOR] isEqualToString:VA_DOOR_CLOSED]) {
                    //open the door
                    objectDetails[@"message"] = @"The door is closed. Do you want to open the door?";
                    objectDetails[@"status"] = VA_DOOR_CLOSED;
                }
                else {
                    //close the door
                    objectDetails[@"message"] = @"The door is opened. Do you want to close the door?";
                    objectDetails[@"status"] = VA_DOOR_OPENED;
                }
                openModal = YES;
            }
            else if(beacon.proximity == CLProximityFar) {
                beaconPlace = @"Far";
            }
            else {
                beaconPlace = @"Unknown";
            }
            if(openModal) {
                if(!isModalPresented) {
                    [self presentObjectDetectedVC: objectDetails];
                }
            }
            else {
                if(objectVC != nil && isModalPresented) {
                    [objectVC dismissViewControllerAnimated:YES completion:nil];
                }
            }
            [beaconStatus setText: [NSString stringWithFormat:@"%d - %@", counter++, beaconPlace]];
        }
    }
    else if([region.identifier isEqualToString:VA_MUSIC_ROOM]) {
        
    }
}

-(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    NSLog(@"Error %@", error);
}

-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Error %@", error);
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error %@", error);
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"did enter - %@", region);
}

-(void)initBeacon {
    
    NSString *idString = VA_UUID;
    //same UUID can be used for multiple beacons. The proximity id can be used to identify them uniquely. One location can have one UUID and multiple beacons
    NSUUID * uuid = [[NSUUID alloc] initWithUUIDString: idString];//[UIDevice currentDevice].identifierForVendor;
    
    beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier: VA_DOOR];
    //[self.locationManager requestAlwaysAuthorization];
    
    if([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    [self.locationManager startMonitoringForRegion:beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];
}

-(void)initDefaults {
    isModalPresented = NO; 
    counter = 0;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    objectVC = (ObjectViewController *)[storyboard instantiateViewControllerWithIdentifier:@"objectVC"];
    objectVC.modalPresentationStyle = UIModalPresentationFullScreen;
    objectVC.didDismiss = ^(NSString *data) {
        // this method gets called in MainVC when your SecondVC is dismissed
        NSLog(@"Dismissed SecondViewController");
        isModalPresented = NO;
    };
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initDefaults];
    
    [Utility initDatabase];
    
    [self initBeacon];
    [self checkStatus:VA_DOOR];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
