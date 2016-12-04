//
//  Utility.m
//  VAssist
//
//  Created by Jeyabalaji T M on 22/10/16.
//  Copyright © 2016 Ant and Buffalo. All rights reserved.
//

#import "Utility.h"
#import "AppDelegate.h"
#import "Device+CoreDataProperties.h"
#import "Message+CoreDataProperties.h"
#import "Constants.h"

@implementation Utility

+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+(void)initDatabase {
    
    NSDictionary *fileContent = [Utility fileContentForTheKey:nil fromPlist:@"Devices"];
    BOOL isDeleteAll = [fileContent objectForKey:@"deleteAll"];
    if(isDeleteAll) {
        [Utility deleteAllObjects:@"Device"];
        [Utility deleteAllObjects:@"Message"];
    }
    
    NSLog(@"doc - %@", [Utility applicationDocumentsDirectory]);
    NSMutableArray *records = [Utility recordsForThePredicate:nil forTable:@"Device"];
    NSLog(@"records -- %@", records);
    
    if(records.count == 0) {
        
        NSArray *devicesPlist = [fileContent objectForKey:@"Devices"];
        for (int i=0; i < devicesPlist.count; i++) {
            
            NSDictionary *devicePlist = devicesPlist[i];
            Device *device = [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext:[Utility context]];
            device.p_id = devicePlist[@"p_id"];
            device.p_desc = devicePlist[@"p_desc"];
            device.p_status = devicePlist[@"p_status"];
            
            NSArray *messagesPlist = devicePlist[@"message"];
            NSMutableArray *messagesManagedObject = [[NSMutableArray alloc] init];
            
            for (int j=0; j < messagesPlist.count; j++) {
                NSDictionary *messagePlist = messagesPlist[j];
                Message *doorMessage = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[Utility context]];
                doorMessage.m_id = messagePlist[@"m_id"];
                doorMessage.p_id = messagePlist[@"p_id"];
                doorMessage.p_status = messagePlist[@"p_status"];
                doorMessage.p_action = messagePlist[@"p_action"];
                doorMessage.rp_action = messagePlist[@"rp_action"];
                doorMessage.desc = messagePlist[@"desc"];
                [messagesManagedObject addObject:doorMessage];
                messagePlist = nil;
                doorMessage = nil;
            }
            device.message = [NSSet setWithArray: messagesManagedObject];
            [Utility saveCurrentContext];
            device = nil;
            devicePlist = nil;
            messagesPlist = nil;
            messagesManagedObject = nil;
        }
        
//        
//        Message *doorMessage1 = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[Utility context]];
//        doorMessage1.m_id = @"101";
//        doorMessage1.p_id = VA_DOOR;
//        doorMessage1.p_status = VA_DOOR_CLOSED;
//        doorMessage1.p_action = VA_DOOR_OPENED;
//        doorMessage1.rp_action = @"open";
//        doorMessage1.desc = @"You are near bed room door. The door is closed. Do you want to open the door?";
//        
//        
//        Message *doorMessage2 = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[Utility context]];
//        doorMessage2.m_id = @"102";
//        doorMessage2.p_id = VA_DOOR;
//        doorMessage2.p_status = VA_DOOR_OPENED;
//        doorMessage2.p_action = VA_DOOR_CLOSED;
//        doorMessage2.rp_action = @"close";
//        doorMessage2.desc = @"You are near bed room door. The door is opened. Do you want to close the door?";
//        
//        Device *device = [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext:[Utility context]];
//        device.p_id = VA_DOOR;
//        device.p_desc = @"Room Door";
//        device.p_status = VA_DOOR_CLOSED;
//        device.message = [NSSet setWithObjects: doorMessage1, doorMessage2, nil];
//
//        
//        Message *musicMessage1 = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[Utility context]];
//        musicMessage1.m_id = @"103";
//        musicMessage1.p_id = VA_MUSIC_ROOM;
//        musicMessage1.p_status = VA_MUSIC_OFF;
//        musicMessage1.p_action = VA_MUSIC_ON;
//        musicMessage1.rp_action = @"on";
//        musicMessage1.desc = @"You are near music room. The music is off. Do you want to play music?";
//        
//        Message *musicMessage2 = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[Utility context]];
//        musicMessage2.m_id = @"104";
//        musicMessage2.p_id = VA_MUSIC_ROOM;
//        musicMessage2.p_status = VA_MUSIC_ON;
//        musicMessage2.p_action = VA_MUSIC_OFF;
//        musicMessage2.rp_action = @"off";
//        musicMessage2.desc = @"You are near music room. The music is playing. Do you want to stop music?";
//        
//        Device *device1 = [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext:[Utility context]];
//        device1.p_id = VA_MUSIC_ROOM;
//        device1.p_desc = @"Music Room";
//        device1.p_status = VA_MUSIC_OFF;
//        device1.message = [NSSet setWithObjects: musicMessage1, musicMessage2, nil];
//        
//        [Utility saveCurrentContext];
    }
}

+(void)saveCurrentContext {
    AppDelegate *myDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [myDelegate saveContext];
}

+(NSManagedObjectContext *)context {
    AppDelegate *myDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [myDelegate managedObjectContext];
    return context;
}

+ (void) deleteAllObjects: (NSString *) entityDescription {
    NSManagedObjectContext *context = [Utility context];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *managedObject in items) {
        [context deleteObject:managedObject];
        NSLog(@"%@ object deleted",entityDescription);
    }
    if (![context save:&error]) {
        NSLog(@"Error deleting %@ - error:%@",entityDescription,error);
    }
}

+(NSMutableArray *)recordsForThePredicate:(NSPredicate *)thePredicate forTable:(NSString *)theTable {
    NSManagedObjectContext *context = [Utility context];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:theTable inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:thePredicate];
    
    NSLog(@"predicate is %@ table name %@", thePredicate, theTable);
    
    NSError *error;
    NSMutableArray *resultArray = [[context executeFetchRequest:fetchRequest error:&error] mutableCopy];
    return resultArray;
}

+(id)fileContentForTheKey:(NSString *)givenKey fromPlist:(NSString *)plistFileName {
    NSString *labelNamesPath = [[NSBundle mainBundle] pathForResource:plistFileName ofType:@"plist"];
    NSDictionary *labelNameList = [[NSDictionary alloc] initWithContentsOfFile:labelNamesPath];
    if(givenKey == nil) {
        return labelNameList;
    }
    return [labelNameList objectForKey:givenKey];
}



@end
