//
//  KSManagedObject.h
//  KSFramework
//
//  Created by Karim Sallam on 23/07/12.
//  Copyright (c) 2012 Karim Sallam. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface KSManagedObject : NSManagedObject

+ (void)cacheWithIds:(NSArray *)ids
managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (void)cacheWithIds:(NSArray *)ids
relationshipKeyPaths:(NSArray *)keyPaths
managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (id)updateOrInsertWithDictionary:(NSDictionary *)dictionary
                         idKeyPath:(NSString *)idKeyPath
              managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (void)flushCache;

#pragma mark - Overrides

+ (NSString *)idKeyName;

- (void)updateWithDictionary:(NSDictionary *)dictionary;

@end
