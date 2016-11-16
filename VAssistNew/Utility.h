//
//  Utility.h
//  VAssist
//
//  Created by Jeyabalaji T M on 22/10/16.
//  Copyright © 2016 Ant and Buffalo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Utility : NSObject

+(void)initDatabase;

+(void)saveCurrentContext;

+(NSManagedObjectContext *)context;

+(NSMutableArray *)recordsForThePredicate:(NSPredicate *)thePredicate forTable:(NSString *)theTable;

+(id)fileContentForTheKey:(NSString *)givenKey fromPlist:(NSString *)plistFileName;

+(void) deleteAllObjects: (NSString *) entityDescription;

@end
