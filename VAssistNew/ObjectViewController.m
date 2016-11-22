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
#import <AVFoundation/AVFoundation.h>

#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEPocketsphinxController.h>


@interface ObjectViewController () <OEEventsObserverDelegate>

@property (weak, nonatomic) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet UILabel *beaconStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblNavTitle;
@property (weak, nonatomic) IBOutlet UIView *vwOpenEarsStatus;
@property (strong, nonatomic) OEEventsObserver *openEarsEventsObserver;

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

-(void)updateDoorStatusLocally:(NSString *)newStatus {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"p_id == %@", VA_DOOR];
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
    
    if(self.objectDetails[@"type"] == VA_DOOR) {
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
                [self updateDoorStatusLocally:newStatus];
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
                [self updateDoorStatusLocally:newStatus];
            } failure:^(NSURLSessionTask *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
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

- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    self.vwOpenEarsStatus.backgroundColor = [UIColor yellowColor];
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
    [self.vwOpenEarsStatus.layer setCornerRadius:12.5];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.lblNavTitle.text = self.objectDetails[@"title"];
    self.lblMessage.text = self.objectDetails[@"message"];
    
    //display voice message here
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconStatus:) name:@"beaconStatus" object:nil];
    
    [self formatViews];
    [self initOpenEars];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.lblNavTitle.text = self.objectDetails[@"title"];
    self.lblMessage.text = self.objectDetails[@"message"];
    
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc]init];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString: self.objectDetails[@"message"]];
    //AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:@&quot;en-GB&quot;];
    
    [synthesizer speakUtterance:utterance];
    
    [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil];
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.lmPath dictionaryAtPath:self.dicPath acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:NO]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" to perform Spanish recognition instead of English.
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[OEPocketsphinxController sharedInstance] stopListening];
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
