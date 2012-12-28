//
//  Event.h
//  Kulturkalender
//
//  Created by Christian Rasmussen on 17.11.12.
//  Copyright (c) 2012 Under Dusken. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocalizedDescription, LocalizedFeatured;

@interface Event : NSManagedObject

@property (nonatomic, retain) NSNumber * ageLimit;
@property (nonatomic, retain) NSNumber * categoryID;
@property (nonatomic, retain) NSDate * endAt;
@property (nonatomic, retain) NSString * eventID;
@property (nonatomic, retain) NSNumber * favorite;
@property (nonatomic, retain) NSNumber * featured;
@property (nonatomic, retain) NSString * imageID;
@property (nonatomic, retain) NSDecimalNumber * price;
@property (nonatomic, retain) NSDate * startAt;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * placeName;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSSet *localizedDescription;
@property (nonatomic, retain) NSSet *localizedFeatured;
@end

@interface Event (CoreDataGeneratedAccessors)

- (void)addLocalizedDescriptionObject:(LocalizedDescription *)value;
- (void)removeLocalizedDescriptionObject:(LocalizedDescription *)value;
- (void)addLocalizedDescription:(NSSet *)values;
- (void)removeLocalizedDescription:(NSSet *)values;

- (void)addLocalizedFeaturedObject:(LocalizedFeatured *)value;
- (void)removeLocalizedFeaturedObject:(LocalizedFeatured *)value;
- (void)addLocalizedFeatured:(NSSet *)values;
- (void)removeLocalizedFeatured:(NSSet *)values;

@end