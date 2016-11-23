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
    NSLog(@"doc - %@", [Utility applicationDocumentsDirectory]);
    NSMutableArray *records = [Utility recordsForThePredicate:nil forTable:@"Device"];
    NSLog(@"records -- %@", records);
    
    if(records.count == 0) {
        Message *doorMessage1 = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[Utility context]];
        doorMessage1.m_id = @"101";
        doorMessage1.p_id = VA_DOOR;
        doorMessage1.p_status = VA_DOOR_CLOSED;
        doorMessage1.p_action = VA_DOOR_OPENED;
        doorMessage1.rp_action = @"open";
        doorMessage1.desc = @"The door is closed. Do you want to open the door?";
        
        
        Message *doorMessage2 = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[Utility context]];
        doorMessage2.m_id = @"102";
        doorMessage2.p_id = VA_DOOR;
        doorMessage2.p_status = VA_DOOR_OPENED;
        doorMessage2.p_action = VA_DOOR_CLOSED;
        doorMessage2.rp_action = @"close";
        doorMessage2.desc = @"The door is opened. Do you want to close the door?";
        
        Device *device = [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext:[Utility context]];
        device.p_id = VA_DOOR;
        device.p_desc = @"Room Door";
        device.p_status = VA_DOOR_CLOSED;
        device.message = [NSSet setWithObjects: doorMessage1, doorMessage2, nil];

        
        Message *musicMessage1 = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[Utility context]];
        musicMessage1.m_id = @"103";
        musicMessage1.p_id = VA_MUSIC_ROOM;
        musicMessage1.p_status = VA_MUSIC_OFF;
        musicMessage1.p_action = VA_MUSIC_ON;
        musicMessage1.rp_action = @"on";
        musicMessage1.desc = @"You are near music room. Do you want to play music?";
        
        Message *musicMessage2 = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[Utility context]];
        musicMessage2.m_id = @"104";
        musicMessage2.p_id = VA_MUSIC_ROOM;
        musicMessage2.p_status = VA_MUSIC_ON;
        musicMessage2.p_action = VA_MUSIC_OFF;
        musicMessage2.rp_action = @"off";
        musicMessage2.desc = @"You are near music room. The music is playing. Do you want to stop music?";
        
        Device *device1 = [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext:[Utility context]];
        device1.p_id = VA_MUSIC_ROOM;
        device1.p_desc = @"Music Room";
        device1.p_status = VA_MUSIC_OFF;
        device1.message = [NSSet setWithObjects: musicMessage1, musicMessage2, nil];
        
        [Utility saveCurrentContext];
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
