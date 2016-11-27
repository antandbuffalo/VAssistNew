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
#import "Message+CoreDataProperties.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AVFoundation/AVFoundation.h>

#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEPocketsphinxController.h>


@interface ObjectViewController () <OEEventsObserverDelegate, AVSpeechSynthesizerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnYes;
@property (weak, nonatomic) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet UILabel *beaconStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblNavTitle;
@property (weak, nonatomic) IBOutlet UIView *vwOpenEarsStatus;
@property (strong, nonatomic) OEEventsObserver *openEarsEventsObserver;
@property (strong, nonatomic) AVSpeechSynthesizer *synthesizer;


@property (strong, nonatomic) NSString *lmPath;
@property (strong, nonatomic) NSString *dicPath;

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

-(void)updateDoorStatusLocally:(NSString *)newStatus toDevice:(NSString *)deviceId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"p_id == %@", deviceId];
    NSArray *records = [Utility recordsForThePredicate:predicate forTable:@"Device"];
    if(records.count > 0) {
        Device *device = [records objectAtIndex:0];
        device.p_status = newStatus;
        [Utility saveCurrentContext];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    if(self.didDismiss) {
        self.didDismiss(@"complete");
    }
}

- (IBAction)btnYesAction:(UIButton *)sender {
    //send service call to RP to open or close
    
    NSString *action = self.objectDetails[@"action"];
    NSString *urlString = [NSString stringWithFormat:@"%@/access", VA_RP_SERVER_ADDRESS];
    NSLog(@"server address - %@", urlString);
    NSURL *URL = [NSURL URLWithString:urlString];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *request = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: self.objectDetails[@"deviceId"], action, nil] forKeys: [NSArray arrayWithObjects: @"deviceId", @"action", nil]];
    
    [manager POST:URL.absoluteString parameters:request progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        if(responseObject[@"error"] == nil) {
            [self updateDoorStatusLocally: self.objectDetails[@"action"] toDevice:self.objectDetails[@"deviceId"]];
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
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

-(void)initOpenEars {
    self.openEarsEventsObserver = [[OEEventsObserver alloc] init];
    [self.openEarsEventsObserver setDelegate:self];
    
    OELanguageModelGenerator *lmGenerator = [[OELanguageModelGenerator alloc] init];
    
    NSArray *words = [NSArray arrayWithObjects:@"YES", @"NO", nil];
    
    NSError *err = [lmGenerator generateLanguageModelFromArray:words withFilesNamed:VA_LANGUAGE_FILE forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" to create a Spanish language model instead of an English one.
    
    if(err == nil) {
        
        self.lmPath = [lmGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName: VA_LANGUAGE_FILE];
        self.dicPath = [lmGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName: VA_LANGUAGE_FILE];
        
    } else {
        NSLog(@"Error: %@",[err localizedDescription]);
    }
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    [self startVoiceToTextListening];
}

-(void)startVoiceToTextListening {
    [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil];
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.lmPath dictionaryAtPath:self.dicPath acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:NO]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" to perform Spanish recognition instead of English.
}

- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    self.vwOpenEarsStatus.backgroundColor = [UIColor yellowColor];
    if([hypothesis isEqualToString:@"YES"]) {
        [self btnYesAction:nil];
    }
}

- (void) pocketsphinxDidStartListening {
    NSLog(@"Pocketsphinx is now listening.");
    self.vwOpenEarsStatus.backgroundColor = [UIColor greenColor];
}

- (void) pocketsphinxDidDetectSpeech {
    NSLog(@"Pocketsphinx has detected speech.");
    self.vwOpenEarsStatus.backgroundColor = [UIColor greenColor];
}

- (void) pocketsphinxDidDetectFinishedSpeech {
    NSLog(@"Pocketsphinx has detected a period of silence, concluding an utterance.");
    self.vwOpenEarsStatus.backgroundColor = [UIColor greenColor];
}

- (void) pocketsphinxDidStopListening {
    NSLog(@"Pocketsphinx has stopped listening.");
    self.vwOpenEarsStatus.backgroundColor = [UIColor redColor];
}

- (void) pocketsphinxDidSuspendRecognition {
    NSLog(@"Pocketsphinx has suspended recognition.");
    self.vwOpenEarsStatus.backgroundColor = [UIColor redColor];
}

- (void) pocketsphinxDidResumeRecognition {
    NSLog(@"Pocketsphinx has resumed recognition.");
    self.vwOpenEarsStatus.backgroundColor = [UIColor greenColor];
}

- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
    NSLog(@"Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
}

- (void) pocketSphinxContinuousSetupDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"Listening setup wasn't successful and returned the failure reason: %@", reasonForFailure);
    self.vwOpenEarsStatus.backgroundColor = [UIColor redColor];
}

- (void) pocketSphinxContinuousTeardownDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"Listening teardown wasn't successful and returned the failure reason: %@", reasonForFailure);
    self.vwOpenEarsStatus.backgroundColor = [UIColor redColor];
}

- (void) testRecognitionCompleted {
    NSLog(@"A test file that was submitted for recognition is now complete.");
    
}

-(void)formatViews {
    [self.vwOpenEarsStatus.layer setCornerRadius:10];
    [self.btnYes.layer setCornerRadius:80];
    
    //[self.lblMessage.layer setCornerRadius:20];
    [self.lblMessage.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.lblMessage.layer setShadowOpacity:0.3];
    [self.lblMessage.layer setShadowRadius:2.0];
    [self.lblMessage.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
}

-(void)getDeviceDetails {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"p_id == %@", self.objectDetails[@"deviceId"]];
    NSMutableArray *records = [Utility recordsForThePredicate:predicate forTable:@"Device"];
    if(records.count > 0) {
        Device *device = [records objectAtIndex:0];
        NSLog(@"sta - %@", device.p_status);

        Message *message = nil;
        NSArray *messages = [device.message allObjects];
        for(int i=0; i < messages.count; i++) {
            message = (Message *)messages[i];
            if([device.p_status isEqualToString:message.p_status]) {
                break;
            }
        }
        
        self.objectDetails[@"title"] = device.p_desc;
        self.objectDetails[@"deviceId"] = device.p_id;
        self.objectDetails[@"message"] = message.desc;
        self.objectDetails[@"status"] = message.p_status;
        self.objectDetails[@"action"] = message.p_action;
        self.objectDetails[@"rpaction"] = message.rp_action;
    }
}

-(void)updateLocalDeviceStatusWithDeviceId:(NSString *)deviceId andStatus:(NSString *)deviceStatus {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"p_id == %@", deviceId];
    NSMutableArray *records = [Utility recordsForThePredicate:predicate forTable:@"Device"];
    if(records.count > 0) {
        Device *device = [records objectAtIndex:0];

        if(![deviceStatus isEqualToString:device.p_status]) {
            device.p_status = deviceStatus;
            [Utility saveCurrentContext];
        }
    }
}

-(void)getDeviceStatusFromRP {
    NSString *urlString = [NSString stringWithFormat:@"%@/device/%@", VA_RP_SERVER_ADDRESS, self.objectDetails[@"deviceId"]];
//    NSString *urlString = [NSString stringWithFormat:@"%@/device/11", VA_RP_SERVER_ADDRESS];

    NSLog(@"server address - %@", urlString);
    
    NSURL *URL = [NSURL URLWithString:urlString];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        int status = [responseObject[@"status"] intValue];
        
        NSLog(@"JSON: %@", responseObject);
        NSLog(@"JSON: %@", (NSString *)responseObject[@"status"]);
        //NSLog(@"type %@", [status class]);
        if(status == 1) {
            NSLog(@"good");
            NSString *deviceId = (NSString *)responseObject[@"device"][@"p_id"];
            NSString *deviceStatus = (NSString *)responseObject[@"device"][@"d_status"];
            
            [self updateLocalDeviceStatusWithDeviceId:deviceId andStatus:deviceStatus];
            [self getDeviceDetails];
            
            self.lblNavTitle.text = self.objectDetails[@"title"];
            self.lblMessage.text = self.objectDetails[@"message"];
            
            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString: self.objectDetails[@"message"]];
            [self.synthesizer speakUtterance:utterance];
        }
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    self.synthesizer.delegate = self;
    
    self.lblNavTitle.text = self.objectDetails[@"title"];
    self.lblMessage.text = self.objectDetails[@"message"];
    
    //display voice message here
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconStatus:) name:@"beaconStatus" object:nil];
    
    [self formatViews];
    [self initOpenEars];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self getDeviceStatusFromRP];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[OEPocketsphinxController sharedInstance] stopListening];
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
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
