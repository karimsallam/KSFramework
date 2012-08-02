//
//  KSCoreDataClient.m
//  KSFramework
//
//  Created by Karim Sallam on 23/07/12.
//  Copyright (c) 2012 Karim Sallam. All rights reserved.
//

#import "KSCoreDataClient.h"

@interface KSCoreDataClient ()

- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification;

- (NSURL *)applicationCachesDirectory;

@end

@implementation KSCoreDataClient

@synthesize managedObjectModelName;
@synthesize databaseName;
@synthesize bundleName;
@synthesize managedObjectModel;
@synthesize mainManagedObjectContext;
@synthesize persistentStoreCoordinator;

- (id)initWithManagedObjectModelName:(NSString *)aManagedObjectModelName
                        databaseName:(NSString *)aDatabaseName
                              bundle:(NSString *)bundleNameOrNil
{
  self = [super init];
  if (self)
  {
    managedObjectModelName = [aManagedObjectModelName copy];
    databaseName = [aDatabaseName copy];
    bundleName = [bundleNameOrNil copy];
  }
  return self;
}

- (id)initWithManagedObjectModel:(NSManagedObjectModel *)aManagedObjectModel
{
  self = [super init];
  if (self)
  {
    managedObjectModel = [aManagedObjectModel copy];
  }
  return self;
}

- (void)dealloc
{
  [self saveContext];
}

- (BOOL)saveContext
{
	if (![self.mainManagedObjectContext hasChanges]) return YES;
  
	NSError *error = nil;
	if (![self.mainManagedObjectContext save:&error])
  {
    NSLog(@"Error while saving: %@", [error localizedDescription]);
    NSArray *detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if (detailedErrors && [detailedErrors count])
    {
      for (NSError *detailedError in detailedErrors)
      {
        NSLog(@"Detailed Error: %@", [detailedError userInfo]);
      }
    }
    else
    {
      NSLog(@"%@", [error userInfo]);
    }
    return NO;
	}
	return YES;
}

/* The NSManagedObjectContext in the NSOperation is on a background thread.
 * We want merge notifications to happen on the main thread and there is no
 * need to act on the main thread's own merge notifications.
 */
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification
{
	if (self.mainManagedObjectContext != [notification object])
  {
		[self.mainManagedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                                    withObject:notification
                                                 waitUntilDone:NO];
  }
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)mainManagedObjectContext
{
	if (mainManagedObjectContext) return mainManagedObjectContext;
  
	// Create the main object context only on the main thread
	if (![NSThread isMainThread])
  {
		[self performSelectorOnMainThread:@selector(mainManagedObjectContext)
                           withObject:nil
                        waitUntilDone:YES];
		return mainManagedObjectContext;
	}
  
	mainManagedObjectContext = [[NSManagedObjectContext alloc] init];
	[mainManagedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
  [mainManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(mergeChangesFromContextDidSaveNotification:)
                                               name:NSManagedObjectContextDidSaveNotification
                                             object:nil];
	return mainManagedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
	if (managedObjectModel) return managedObjectModel;
  
  if (!self.managedObjectModelName) return nil;
  
  NSString *momPath = self.managedObjectModelName;
  if (bundleName)
  {
    momPath = [NSString stringWithFormat:@"%@/%@", bundleName, self.managedObjectModelName];
  }
  
  NSURL *objectModelURL = [[NSBundle mainBundle] URLForResource:momPath
                                                  withExtension:@"momd"];
  if (!objectModelURL)
  {
    objectModelURL = [[NSBundle mainBundle] URLForResource:momPath
                                             withExtension:@"mom"];
  }
  managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:objectModelURL];
  return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if (persistentStoreCoordinator) return persistentStoreCoordinator;
  
  if (!self.managedObjectModel) return nil;
  
  if (!self.databaseName) return nil;
  
  NSURL *storeURL = [[self applicationCachesDirectory] URLByAppendingPathComponent:self.databaseName];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                           [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                           nil];
  NSError *error = nil;
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                configuration:nil
                                                          URL:storeURL
                                                      options:options
                                                        error:&error])
  {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    [[NSFileManager defaultManager] removeItemAtURL:[[self applicationCachesDirectory] URLByAppendingPathComponent:self.databaseName]
                                              error:nil];
		[persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                             configuration:nil
                                                       URL:storeURL
                                                   options:nil
                                                     error:&error];
	}
	return persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext
{
	NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
	[managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	return managedObjectContext;
}

#pragma mark - Application's Caches directory

- (NSURL *)applicationCachesDirectory
{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
