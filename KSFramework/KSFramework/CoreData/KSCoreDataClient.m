//
//  KSCoreDataClient.m
//  KSFramework
//
//  Created by Karim Sallam on 23/07/12.
//  Copyright (c) 2012 Karim Sallam. All rights reserved.
//

#import "KSCoreDataClient.h"

@interface KSCoreDataClient ()

@property (strong, nonatomic) NSManagedObjectModel          *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext        *mainManagedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator  *persistentStoreCoordinator;

@end

@implementation KSCoreDataClient

- (id)initWithManagedObjectModelName:(NSString *)managedObjectModelName
                        databaseName:(NSString *)databaseName
                              bundle:(NSString *)bundleNameOrNil
                          folderName:(NSString *)folderNameOrNil
{
  if (!(self = [super init])) return nil;
  
  _managedObjectModelName = [managedObjectModelName copy];
  _databaseName = [databaseName copy];
  _bundleName = [bundleNameOrNil copy];
  _folderName = [folderNameOrNil copy];
  
  return self;
}

- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
                    databaseName:(NSString *)databaseName
                      folderName:(NSString *)folderNameOrNil
{
  if (!(self = [super init])) return nil;
  
  _managedObjectModel = [managedObjectModel copy];
  _databaseName = [databaseName copy];
  _folderName = [folderNameOrNil copy];
  
  return self;
}

- (void)dealloc
{
  [self saveContext];
}

#pragma mark - Core Data stack

- (NSManagedObjectModel *)managedObjectModel
{
	if (_managedObjectModel)      return _managedObjectModel;
  if (!_managedObjectModelName) return nil;
  
  NSString *momPath = _managedObjectModelName;
  if (_bundleName) {
    momPath = [NSString stringWithFormat:@"%@/%@", _bundleName, _managedObjectModelName];
  }
  
  NSURL *objectModelURL = [[NSBundle mainBundle] URLForResource:momPath withExtension:@"momd"];
  if (!objectModelURL) {
    objectModelURL = [[NSBundle mainBundle] URLForResource:momPath withExtension:@"mom"];
  }
  
  return _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:objectModelURL];
}

- (NSManagedObjectContext *)mainManagedObjectContext
{
	if (_mainManagedObjectContext) return _mainManagedObjectContext;
  
	// Create the main object context only on the main thread.
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(mainManagedObjectContext) withObject:nil waitUntilDone:YES];
		return _mainManagedObjectContext;
	}
  
	_mainManagedObjectContext = [[NSManagedObjectContext alloc] init];
	[_mainManagedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
  [_mainManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(mergeChangesFromContextDidSaveNotification:)
                                               name:NSManagedObjectContextDidSaveNotification
                                             object:nil];
  
	return _mainManagedObjectContext;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if (_persistentStoreCoordinator)  return _persistentStoreCoordinator;
  
  if (!self.managedObjectModel)     return nil;
  if (!_databaseName)               return nil;
  
  NSURL *storeURL = [self storeURL];
  if (!storeURL)                    return nil;

	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                           [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                           nil];
  NSError *error = nil;
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                 configuration:nil
                                                           URL:storeURL
                                                       options:options
                                                         error:&error]) {
    NSLog(@"Can't add/merge persistent store: %@", error);
    if (![[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]) {
      NSLog(@"Can't remove previous persistent store file: %@, %@", error, [error userInfo]);
    }
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:nil
                                                           error:&error]) {
      NSLog(@"Can't add new persistent store: %@, %@", error, [error userInfo]);
    }
	}
  
	return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext
{
	NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
	[managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
  
	return managedObjectContext;
}

- (BOOL)saveContext
{
	if (![self.mainManagedObjectContext hasChanges]) return YES;
  
	NSError *error = nil;
	if (![self.mainManagedObjectContext save:&error]) {
    NSLog(@"Error while saving: %@", [error localizedDescription]);
    NSArray *detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if (detailedErrors && [detailedErrors count]) {
      for (NSError *detailedError in detailedErrors) {
        NSLog(@"Detailed Error: %@", [detailedError userInfo]);
      }
    }
    else {
      NSLog(@"%@", [error userInfo]);
    }
    return NO;
	}
	return YES;
}

- (BOOL)reset
{
  NSURL *storeURL = [self storeURL];
  NSPersistentStore *persistentStore = [self.persistentStoreCoordinator persistentStoreForURL:storeURL];
  NSError *error = nil;
  if (![self.persistentStoreCoordinator removePersistentStore:persistentStore error:&error]) {
    NSLog(@"Can't remove persistent store: %@, %@", error, [error userInfo]);
    return NO;
  }
  else {
    if (![[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]) {
      NSLog(@"Can't remove persistent store file: %@, %@", error, [error userInfo]);
      return NO;
    }
    else if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                        configuration:nil
                                                                  URL:storeURL
                                                              options:nil
                                                                error:&error]) {
      NSLog(@"Can't add persistent store: %@, %@", error, [error userInfo]);
      return NO;
    }
  }
  return YES;
}

#pragma mark - Private

/* The NSManagedObjectContext in the NSOperation is on a background thread.
 * We want merge notifications to happen on the main thread and there is no
 * need to act on the main thread's own merge notifications.
 */
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification
{
  if (self.mainManagedObjectContext != [notification object]) {
    [self.mainManagedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                                    withObject:notification
                                                 waitUntilDone:NO];
  }
}

- (NSURL *)storeURL
{
  NSURL *storeURL = [self applicationSupportDirectory];
  if (_folderName) {
    storeURL = [storeURL URLByAppendingPathComponent:_folderName isDirectory:YES];
    
    BOOL isDir = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[storeURL path] isDirectory:&isDir]) {
      NSError *error = nil;
      if (![[NSFileManager defaultManager] createDirectoryAtURL:storeURL
                                    withIntermediateDirectories:YES
                                                     attributes:@{ NSURLIsExcludedFromBackupKey : @(YES) }
                                                          error:&error]) {
        NSLog(@"Can't create database directory: %@", error);
        return nil;
      }
    }
    else if (!isDir) {
      NSLog(@"Database directory name is already taken by a file");
      return nil;
    }
  }
  
  return [storeURL URLByAppendingPathComponent:_databaseName];
}

- (NSURL *)applicationSupportDirectory
{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
