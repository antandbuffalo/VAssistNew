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
#import "Message+CoreDataProperties.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController () {
    CLBeaconRegion *beaconRegion;
    __weak IBOutlet UILabel *beaconStatus;
    int counter;
    NSMutableArray *devices;
    BOOL isModalPresented;
    ObjectViewController *objectVC;
    __weak IBOutlet UIActivityIndicatorView *spinner;
    __weak IBOutlet UILabel *lblStatus;
}

@end

@implementation ViewController

- (IBAction)glowLED:(UIButton *)sender {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%d", [Utility getRPIPAddress], VA_RP_SERVER_CONTEXT, 24];
    NSLog(@"server address - %@", urlString);
    
    NSURL *URL = [NSURL URLWithString:urlString];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //NSDictionary *dic = [NSDictionary dictionaryWithObject:@"0" forKey:@"id"];
    [manager POST:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

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
        return device.p_status;
    }
    return nil;
}

-(void)presentObjectDetectedVC:(NSMutableDictionary *)objectDetails {
    objectVC.objectDetails = objectDetails;
    isModalPresented = YES;
    [self presentViewController:objectVC animated:YES completion:nil];
    [spinner stopAnimating];
}

-(void)openModal:(NSMutableDictionary *)objectDetails {
    
    [self presentObjectDetectedVC: objectDetails];
    
}

-(void)closeModal {
    if(objectVC != nil && isModalPresented) {
        [objectVC dismissViewControllerAnimated:YES completion:nil];
        isModalPresented = NO;
        [spinner startAnimating];
        [[NSNotificationCenter defaultCenter] postNotificationName:VA_NOTIF_MODAL_CLOSED object:nil];
    }
}

-(Device *)getObjectDetails:(int)objectId {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"p_id == %d", objectId];
    NSMutableArray *records = [Utility recordsForThePredicate:predicate forTable:@"Device"];
    if(records.count > 0) {
        Device *device = [records objectAtIndex:0];
        NSLog(@"sta - %@", device.p_status);
        return device;
    }
    return nil;
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
//    NSLog(@"something - %@", beacons);
//    NSLog(@"region - %@", region);
    CLBeacon *beacon;
    NSMutableDictionary *objectDetails = [[NSMutableDictionary alloc] init];
    if([region.identifier isEqualToString:VA_REGION_HOME]) {
        if(beacons != nil && beacons.count > 0) {
            objectDetails[@"type"] = VA_DOOR;
            
            beacon = beacons[0];
            NSString *beaconPlace = @"";
            BOOL openModal = NO;
            
            if(beacon.proximity == CLProximityNear || beacon.proximity == CLProximityImmediate) {
                beaconPlace = @"Near";
                if(!isModalPresented) {
                    Device *device = [self getObjectDetails:[beacon.major intValue]];
//                    Message *message = nil;
//                    NSArray *messages = [device.message allObjects];
//                    for(int i=0; i < messages.count; i++) {
//                        message = (Message *)messages[i];
//                        if([device.p_status isEqualToString:message.p_status]) {
//                            break;
//                        }
//                    }
                    
                    objectDetails[@"title"] = device.p_desc;
                    objectDetails[@"deviceId"] = device.p_id;
//                    objectDetails[@"message"] = message.desc;
//                    objectDetails[@"status"] = message.p_status;
//                    objectDetails[@"action"] = message.p_action;
//                    objectDetails[@"rpaction"] = message.rp_action;

                    [self openModal: objectDetails];
                }
                openModal = YES;
            }
            else if(beacon.proximity == CLProximityFar) {
                beaconPlace = @"Far";
                [self closeModal];
            }
            else {
                beaconPlace = @"Unknown";
                [self closeModal];
            }
            
            [beaconStatus setText: [NSString stringWithFormat:@"%d - %@", counter++, beaconPlace]];
            objectDetails[@"beaconStatus"] = [NSString stringWithFormat:@"%d - %@", counter++, beaconPlace];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"beaconStatus" object:objectDetails];
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
    
    beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier: VA_REGION_HOME];
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
        [spinner startAnimating];
    };
    [spinner startAnimating];
}

-(void)readSettingsBundle {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    NSLog(@"pref - %@", preferences);
    for (int i=0; i < preferences.count; i++) {
        if([preferences[i][@"Type"] isEqualToString: @"PSTextFieldSpecifier"]) {
            NSLog(@"value - %@", preferences[i][@"DefaultValue"]);
            NSLog(@"value - %@", preferences[i][@"name_preference"]);
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *ipaddress = [defaults stringForKey:@"name_preference"];
            NSLog(@"ip - %@", ipaddress);
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initDefaults];
    
    [Utility initDatabase];
    
    [self initBeacon];
    //[self checkStatus:VA_DOOR];

//    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
//    //synthesizer.delegate = self;
//    NSError *error;
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:&error];
//    [[AVAudioSession sharedInstance] setActive:true error:&error];
//    
//    AVSpeechUtterance *bugWorkaroundUtterance = [AVSpeechUtterance speechUtteranceWithString:@"Hello"];
//    //bugWorkaroundUtterance.rate = AVSpeechUtteranceMaximumSpeechRate;
//    [synthesizer speakUtterance:bugWorkaroundUtterance];
    
    //[self readSettingsBundle];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
