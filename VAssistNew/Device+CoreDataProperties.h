//
//  Device+CoreDataProperties.h
//  VAssistNew
//
//  Created by Jeyabalaji T M on 16/11/16.
//  Copyright © 2016 Ant and Buffalo. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Device.h"

NS_ASSUME_NONNULL_BEGIN

@interface Device (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *ble_distance;
@property (nullable, nonatomic, retain) NSString *ble_id;
@property (nullable, nonatomic, retain) NSString *p_desc;
@property (nullable, nonatomic, retain) NSString *p_id;
@property (nullable, nonatomic, retain) NSString *p_status;
@property (nullable, nonatomic, retain) Message *message;

@end

NS_ASSUME_NONNULL_END
