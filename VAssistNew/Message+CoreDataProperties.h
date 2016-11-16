//
//  Message+CoreDataProperties.h
//  VAssistNew
//
//  Created by Jeyabalaji T M on 16/11/16.
//  Copyright © 2016 Ant and Buffalo. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Message.h"

NS_ASSUME_NONNULL_BEGIN

@interface Message (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *desc;
@property (nullable, nonatomic, retain) NSString *m_id;
@property (nullable, nonatomic, retain) NSString *p_id;
@property (nullable, nonatomic, retain) NSString *p_status;

@end

NS_ASSUME_NONNULL_END
