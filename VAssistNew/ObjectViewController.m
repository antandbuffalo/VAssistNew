//
//  ObjectViewController.m
//  VAssist
//
//  Created by Jeyabalaji T M on 13/11/16.
//  Copyright © 2016 Ant and Buffalo. All rights reserved.
//

#import "ObjectViewController.h"
#import "Constants.h"
#import "Utility.h"
#import "Device+CoreDataProperties.h"
#import <AFNetworking/AFHTTPSessionManager.h>

@interface ObjectViewController ()

@property (weak, nonatomic) IBOutlet UINavigationItem *navTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet UILabel *beaconStatus;

@end

@implementation ObjectViewController

-(void)doorActions:(NSString *)action {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@", VA_RP_SERVER_ADDRESS, VA_RP_SERVER_CONTEXT, action];
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

- (IBAction)btnYesAction:(UIButton *)sender {
    //send service call to RP to open or close
    
    if(self.objectDetails[@"type"] == VA_DOOR) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"p_id == %@", VA_DOOR];
        NSArray *records = [Utility recordsForThePredicate:predicate forTable:@"Device"];
        NSString __block *newStatus = @"";

        if(self.objectDetails[@"status"] == VA_DOOR_OPENED) {
            //close the door - send service to RP
            NSString *action = @"close";
            NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@", VA_RP_SERVER_ADDRESS, VA_RP_SERVER_CONTEXT, action];
            NSLog(@"server address - %@", urlString);
            NSURL *URL = [NSURL URLWithString:urlString];
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            [manager POST:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
                NSLog(@"JSON: %@", responseObject);
                newStatus = VA_DOOR_CLOSED;
            } failure:^(NSURLSessionTask *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
        }
        else {
            //open the door - send service to RP
            NSString *action = @"open";
            NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@", VA_RP_SERVER_ADDRESS, VA_RP_SERVER_CONTEXT, action];
            NSLog(@"server address - %@", urlString);
            NSURL *URL = [NSURL URLWithString:urlString];
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            [manager POST:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
                NSLog(@"JSON: %@", responseObject);
                newStatus = VA_DOOR_OPENED;
            } failure:^(NSURLSessionTask *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
        }
        if(records.count > 0) {
            Device *device = [records objectAtIndex:0];
            device.p_status = newStatus;
            [Utility saveCurrentContext];
        }
    }
    else if(self.objectDetails[@"type"] == VA_MUSIC_ROOM) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"p_id == %@", VA_MUSIC_ROOM];
        NSArray *records = [Utility recordsForThePredicate:predicate forTable:@"Device"];
        NSString *newStatus = @"";
        
        if(self.objectDetails[@"status"] == VA_MUSIC_ON) {
            //close the door - send service to RP
            newStatus = VA_MUSIC_OFF;
        }
        else {
            //open the door - send service to RP
            newStatus = VA_MUSIC_ON;
        }
        if(records.count > 0) {
            Device *device = [records objectAtIndex:0];
            device.p_status = newStatus;
            [Utility saveCurrentContext];
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    if(self.didDismiss) {
        self.didDismiss(@"complete");
    }
}

- (IBAction)btnNoAction:(UIButton *)sender {
    //Do nothing
}

- (IBAction)closeModal:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    if(self.didDismiss) {
        self.didDismiss(@"complete");
    }

}

-(void)beaconStatus:(NSNotification *)notification {
    NSLog(@"notif - %@", notification);
    NSDictionary *details = (NSDictionary *)notification.object;
    self.beaconStatus.text = details[@"beaconStatus"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navTitle.title = self.objectDetails[@"title"];
    self.lblMessage.text = self.objectDetails[@"message"];
    
    //display voice message here
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconStatus:) name:@"beaconStatus" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
