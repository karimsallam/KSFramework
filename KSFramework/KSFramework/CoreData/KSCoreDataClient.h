//
//  KSCoreDataClient.h
//  KSFramework
//
//  Created by Karim Sallam on 23/07/12.
//  Copyright (c) 2012 Karim Sallam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface KSCoreDataClient : NSObject

@property(readonly, copy, nonatomic) NSString *managedObjectModelName;
@property(readonly, copy, nonatomic) NSString *databaseName;
@property(readonly, copy, nonatomic) NSString *bundleName;
@property(readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property(readonly, strong, nonatomic) NSManagedObjectContext *mainManagedObjectContext;
@property(readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// To load the managedObjectModel from a bundle.
- (id)initWithManagedObjectModelName:(NSString *)managedObjectModelName
                        databaseName:(NSString *)databaseName
                              bundle:(NSString *)bundleNameOrNil;

// To pass a managedObjectModel.
// The managedObjectModel is copied.
- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;

- (NSManagedObjectContext *)managedObjectContext;

- (BOOL)saveContext;

@end
