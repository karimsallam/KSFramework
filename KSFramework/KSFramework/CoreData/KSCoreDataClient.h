//
//  KSCoreDataClient.h
//  KSFramework
//
//  Created by Karim Sallam on 23/07/12.
//  Copyright (c) 2012 Karim Sallam. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface KSCoreDataClient : NSObject

// To load the managedObjectModel from a bundle. If bundle is nil loads the managedObjectModel from the main bundle.
- (id)initWithManagedObjectModelName:(NSString *)managedObjectModelName
                        databaseName:(NSString *)databaseName
                              bundle:(NSString *)bundleNameOrNil
                          folderName:(NSString *)folderNameOrNil;

// To pass a managedObjectModel. The managedObjectModel is copied.
- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
                    databaseName:(NSString *)databaseName
                      folderName:(NSString *)folderNameOrNil;

@property (readonly, copy, nonatomic) NSString *managedObjectModelName;
@property (readonly, copy, nonatomic) NSString *databaseName;
@property (readonly, copy, nonatomic) NSString *bundleName;
@property (readonly, copy, nonatomic) NSString *folderName;

- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)mainManagedObjectContext;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

- (NSManagedObjectContext *)managedObjectContext;

- (BOOL)saveContext;

// Remove the current persistentStore and create a new empty one.
- (BOOL)reset;

@end
