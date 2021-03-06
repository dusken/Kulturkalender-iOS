//
//  CoreDataEventStore.m
//  Barteguiden
//
//  Created by Christian Rasmussen on 29.12.12.
//  Copyright (c) 2012 Under Dusken. All rights reserved.
//

#import "CoreDataEventStore.h"
#import <CoreData/CoreData.h>

#import "Event.h"
#import "EventStoreCommunicator.h"
#import "EventBuilder.h"
#import "NSError+RIOUnderlyingError.h"
#import "NetworkActivity.h"


static NSString * const kEventEntityName = @"Event";

static NSString * const kEventIDKey = @"eventID";
static NSString * const kTitleKey = @"title";
static NSString * const kStartAtKey = @"startAt";

static NSString * const kFeaturedKey = @"featuredState";
static NSString * const kFavoriteKey = @"favoriteState";

static NSString * const kCategoryIDKey = @"categoryID";
static NSString * const kPriceKey = @"price";
static NSString * const kAgeLimitKey = @"ageLimit";

static NSString * const kPlaceNameKey = @"placeName";
static NSString * const kAddressKey = @"address";
static NSString * const kLatitudeKey = @"latitude";
static NSString * const kLongitudeKey = @"longitude";

static NSString * const kURLKey = @"eventURL";

static NSString * const kCalendarEventIDKey = @"calendarEventID";


@interface CoreDataEventStore () <EventDelegate>

@property (nonatomic, strong) NSManagedObjectContext *backgroundManagedObjectContext;

@end


@implementation CoreDataEventStore

- (instancetype)init
{
    self = [super init];
    if (self) {
        _communicator = [[EventStoreCommunicator alloc] init];
        _communicator.delegate = self;
        _builder = [[EventBuilder alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextObjectsDidChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil]; // NOTE: Object identity is checked in selector
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
}

- (void)refresh
{
    [self notifyWillDownloadData];
    
    [self.communicator downloadEventChanges];
}


#pragma mark - EventStoreCommunicatorDelegate

- (void)communicator:(EventStoreCommunicator *)communicator didReceiveEvents:(NSArray *)events
{
    [self notifyDidDownloadData];
    
    __weak typeof(self) bself = self;
    [self.backgroundManagedObjectContext performBlock:^{
        NSFetchRequest *fetchRequest = [bself fetchRequestWithPredicate:nil];
        NSError *error = nil;
        NSArray *existingEvents = [bself.backgroundManagedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (existingEvents == nil && error != NULL) {
            return;
        }
        
        NSMutableSet *relevantEvents = [[NSMutableSet alloc] init];
        
        for (NSDictionary *jsonObject in events) {
            NSString *eventID = [NSString stringWithFormat:@"%@", jsonObject[@"eventID"]];
            __block Event *event = nil;
            [existingEvents enumerateObjectsUsingBlock:^(Event *obj, NSUInteger idx, BOOL *stop) {
                if ([obj.eventID isEqualToString:eventID]) {
                    event = obj;
                    [relevantEvents addObject:event];
                    *stop = YES;
                }
            }];
            
            if (event != nil) {
                [bself.builder updateEvent:event withJSONObject:jsonObject inManagedObjectContext:bself.backgroundManagedObjectContext];
            }
            else {
                [bself.builder insertNewEventWithJSONObject:jsonObject inManagedObjectContext:bself.backgroundManagedObjectContext];
            }
        }
        
        NSMutableSet *eventsToBeDeleted = [[NSMutableSet alloc] initWithArray:existingEvents];
        [eventsToBeDeleted minusSet:relevantEvents];
        
        for (Event *event in eventsToBeDeleted) {
            [bself.backgroundManagedObjectContext deleteObject:event];
        }
        
        [bself.backgroundManagedObjectContext save:NULL]; // TODO: Fix error handling
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [bself notifyDidRefresh];
        });
    }];
}

- (void)communicator:(EventStoreCommunicator *)communicator didFailWithError:(NSError *)underlyingError
{
    [self notifyDidDownloadData];
    
    NSError *error = [NSError errorWithDomain:EventStoreErrorDomain code:EventStoreFetchRequestFailed underlyingError:underlyingError];
    [[NSNotificationCenter defaultCenter] postNotificationName:EventStoreDidFailNotification object:self userInfo:@{EventStoreErrorUserInfoKey: error}];
}


#pragma mark - Notifications

- (void)managedObjectContextObjectsDidChangeNotification:(NSNotification *)note
{
    if (note.object == self.managedObjectContext) {
        NSSet *inserted = note.userInfo[NSInsertedObjectsKey];
        NSSet *updated = note.userInfo[NSUpdatedObjectsKey];
        NSSet *deleted = note.userInfo[NSDeletedObjectsKey];
        
        [self notifyEventStoreChangedWithInserted:inserted updated:updated deleted:deleted];
    }
    else if (note.object == self.backgroundManagedObjectContext) {
        NSLog(@"Background MOC did change");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.managedObjectContext mergeChangesFromContextDidSaveNotification:note];
        });
    }
}


#pragma mark - Accessing Events

- (id<Event>)eventWithIdentifier:(NSString *)identifier error:(NSError **)error
{
    // Set up fetch request
    NSPredicate *predicate = [self predicateForEventIdentifier:identifier];
    NSFetchRequest *fetchRequest = [self fetchRequestWithPredicate:predicate];
    fetchRequest.fetchLimit = 1;
    
    // Fetch events and forward any errors
    NSArray *events = [self executeFetchRequest:fetchRequest error:error];
    if (events == nil) {
        return nil;
    }
    
    [self setDelegateOnEvents:events];
    
    // Retrieve single event
    if ([events count] > 0) {
        return events[0];
    }
    
    return nil;
}

- (NSArray *)eventsMatchingPredicate:(NSPredicate *)predicate error:(NSError **)error
{
    // Set up fetch request
    NSFetchRequest *fetchRequest = [self fetchRequestWithPredicate:predicate];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    
    // Fetch events and forward any errors
    NSArray *events = [self executeFetchRequest:fetchRequest error:error];
    if (events == nil) {
        return nil;
    }
    
    [self setDelegateOnEvents:events];
    
    return events;
}


#pragma mark - Predicates

- (NSPredicate *)predicateForEventsWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    return [NSPredicate predicateWithFormat:@"%K >= %@ AND %K <= %@", kStartAtKey, startDate, kStartAtKey, endDate];
}

- (NSPredicate *)predicateForFeaturedEvents
{
    return [NSPredicate predicateWithFormat:@"%K == 1", kFeaturedKey];
}

- (NSPredicate *)predicateForFavoritedEvents
{
    return [NSPredicate predicateWithFormat:@"%K == 1", kFavoriteKey];
}

- (NSPredicate *)predicateForPaidEvents
{
    return [NSPredicate predicateWithFormat:@"%K > 0", kPriceKey];
}

- (NSPredicate *)predicateForFreeEvents
{
    return [NSPredicate predicateWithFormat:@"%K == 0", kPriceKey];
}

- (NSPredicate *)predicateForEventsWithCategories:(NSArray *)categories
{
    // TODO: Not tested
    return [NSPredicate predicateWithFormat:@"%K IN %@", kCategoryIDKey, categories];
}

- (NSPredicate *)predicateForEventsAllowedForAge:(NSUInteger)age
{
    // TODO: Not tested
    return [NSPredicate predicateWithFormat:@"%K <= %d", kAgeLimitKey, age];
}

- (NSPredicate *)predicateForTitleContainingText:(NSString *)text
{
    return [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", kTitleKey, text];
}

- (NSPredicate *)predicateForPlaceNameContainingText:(NSString *)text
{
    return [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", kPlaceNameKey, text];
}


#pragma mark - Saving changes

- (BOOL)save:(NSError **)error
{
    NSError *underlyingError = nil;
    if ([self.managedObjectContext hasChanges] && [self.managedObjectContext save:&underlyingError]) {
        return YES;
    }
    
    if (error != NULL) {
        *error = [NSError errorWithDomain:EventStoreErrorDomain code:EventStoreSaveFailed underlyingError:underlyingError];
    }
    
    return NO;
}


#pragma mark - EventDelegate

- (void)eventDidChange:(Event *)event
{
//    NSLog(@"%@%@", NSStringFromSelector(_cmd), event);
    NSSet *updated = [NSSet setWithObject:event];
    [self notifyEventStoreChangedWithInserted:nil updated:updated deleted:nil];
}

- (void)eventStartedDownloadingData:(Event *)event
{
    [self notifyWillDownloadData];
}

- (void)eventFinishedDownloadingData:(Event *)event
{
    [self notifyDidDownloadData];
}

- (NSURL *)URLForImageWithEventID:(NSString *)eventID size:(CGSize)size
{
    return [self.communicator URLForImageWithEventID:eventID size:size];
}


#pragma mark - Private methods

- (NSPredicate *)predicateForEventIdentifier:(NSString *)identifier
{
    return [NSPredicate predicateWithFormat:@"%K == %@", kEventIDKey, identifier];
}

- (NSFetchRequest *)fetchRequestWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kEventEntityName];
    fetchRequest.predicate = predicate;
    
    // Set sort descriptor
    NSSortDescriptor *startAtSortDescriptor = [[NSSortDescriptor alloc] initWithKey:kStartAtKey ascending:YES];
    NSArray *sortDescriptors = @[startAtSortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    return fetchRequest;
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)error
{
    NSError *underlyingError = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&underlyingError];
    if (result == nil && error != NULL) {
        *error = [NSError errorWithDomain:EventStoreErrorDomain code:EventStoreFetchRequestFailed underlyingError:underlyingError];
    }
    
    return result;
}

- (void)setDelegateOnEvents:(NSArray *)events
{
    __weak typeof(self) bself = self;
    [events enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Event *event = (Event *)obj;
        event.delegate = bself;
    }];
}

- (void)notifyEventStoreChangedWithInserted:(NSSet *)inserted updated:(NSSet *)updated deleted:(NSSet *)deleted
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [self addEvents:inserted toUserInfo:userInfo forKey:EventStoreInsertedEventsUserInfoKey];
    [self addEvents:updated toUserInfo:userInfo forKey:EventStoreUpdatedEventsUserInfoKey];
    [self addEvents:deleted toUserInfo:userInfo forKey:EventStoreDeletedEventsUserInfoKey];
    
    if (userInfo[EventStoreInsertedEventsUserInfoKey] == nil && userInfo[EventStoreUpdatedEventsUserInfoKey] == nil && userInfo[EventStoreDeletedEventsUserInfoKey] == nil) {
        return;
    }
    
    // NOTE: Make sure that delegate is set on new events
    [self setDelegateOnEvents:[userInfo[EventStoreInsertedEventsUserInfoKey] allObjects]];
    
//    NSLog(@"%@", userInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName:EventStoreChangedNotification object:self userInfo:[userInfo copy]];
}

- (void)addEvents:(NSSet *)changes toUserInfo:(NSMutableDictionary *)userInfo forKey:(NSString *)key
{
    NSMutableSet *events = [NSMutableSet set];
    [changes enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        if ([obj isKindOfClass:[Event class]]) {
            [events addObject:obj];
        }
    }];
    
    if ([events count] > 0) {
        userInfo[key] = [events copy];
    }
}

- (void)notifyWillDownloadData
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] postNotificationName:EventStoreWillDownloadDataNotification object:self];
}

- (void)notifyDidDownloadData
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] postNotificationName:EventStoreDidDownloadDataNotification object:self];
}

- (void)notifyDidRefresh
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] postNotificationName:EventStoreDidRefreshNotification object:self];
}


- (void)notifyDidFail:(NSError *)error
{
    NSDictionary *userInfo = nil;
    if (error != nil) {
        userInfo = @{EventStoreErrorUserInfoKey: error};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:EventStoreDidFailNotification object:self userInfo:userInfo];
}


#pragma mark - Core Data setup

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectContext *)backgroundManagedObjectContext
{
    if (_backgroundManagedObjectContext != nil) {
        return _backgroundManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _backgroundManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_backgroundManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _backgroundManagedObjectContext;
}


- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"EventKit" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"EventKit.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error] == nil) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end