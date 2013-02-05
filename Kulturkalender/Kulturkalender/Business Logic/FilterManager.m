//
//  FilterManager.m
//  Kulturkalender
//
//  Created by Christian Rasmussen on 01.11.12.
//  Copyright (c) 2012 Under Dusken. All rights reserved.
//

#import "FilterManager.h"
#import "EventKit.h"

NSString * const kCategoryFilterSelectionKey = @"CategoryFilterSelection";
NSString * const kAgeLimitFilterMyAgeKey = @"AgeLimitFilterMyAge";
NSString * const kAgeLimitFilterSelectionKey = @"AgeLimitFilterSelection";
NSString * const kPriceFilterSelectionKey = @"PriceFilterSelection";

@implementation FilterManager {
    NSUserDefaults *_userDefaults;
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults
{
    self = [super init];
    if (self) {
        _userDefaults = userDefaults;
    }
    return self;
}

- (void)save
{
    [_userDefaults synchronize];
}


#pragma mark - Predicate

//- (NSPredicate *)predicate
//{
//    NSMutableArray *predicates = [[NSMutableArray alloc] init];
//    
//    // Category filter
//    NSPredicate *categoryPredicate = [self.eventStore predicateForEventsWithCategoryIDs:self.selectedCategoryIDs];
//    [predicates addObject:categoryPredicate];
//    
//    // Age filter
//    if (self.ageLimitFilter == AgeLimitFilterShowAllowedForMyAge && [self.myAge unsignedIntegerValue] > 0) {
//        NSPredicate *ageLimitFilter = [self.eventStore predicateForEventsAllowedForAge:[self.myAge unsignedIntegerValue]];
//        [predicates addObject:ageLimitFilter];
//    }
//    
//    // Price filter
//    if (self.priceFilter == PriceFilterShowPaidEvents) {
//        NSPredicate *priceFilter = [self.eventStore predicateForPaidEvents];
//        [predicates addObject:priceFilter];
//    }
//    else if (self.priceFilter == PriceFilterShowFreeEvents) {
//        NSPredicate *priceFilter = [self.eventStore predicateForFreeEvents];
//        [predicates addObject:priceFilter];
//    }
//    
//    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
//    return predicate;
//}


#pragma mark - Defaults


#pragma mark - Category filter

//- (BOOL)isSelectedForCategoryID:(NSNumber *)categoryID
//{
//    BOOL isSelected = ([_selectedCategories containsObject:categoryID] == YES);
//    return isSelected;
//}
//
//- (void)setSelected:(BOOL)selected forCategoryID:(NSNumber *)categoryID
//{
//    if (selected == YES) {
//        [_selectedCategories addObject:categoryID];
//    }
//    else {
//        [_selectedCategories removeObject:categoryID];
//    }
//}
//
//- (void)toggleSelectedForCategoryID:(NSNumber *)categoryID
//{
//    BOOL isSelected = [self isSelectedForCategoryID:categoryID];
//    [self setSelected:(isSelected == NO) forCategoryID:categoryID];
//}
//
//
#pragma mark - Age limit filter

- (AgeLimitFilter)ageLimitFilter
{
    NSNumber *ageLimitFilter = [_userDefaults objectForKey:kAgeLimitFilterSelectionKey];
    if (ageLimitFilter == nil) {
        return AgeLimitFilterShowAllEvents;
    }
    
    return [ageLimitFilter integerValue];
}

- (void)setAgeLimitFilter:(AgeLimitFilter)ageLimitFilter
{
    [_userDefaults setObject:@(ageLimitFilter) forKey:kAgeLimitFilterSelectionKey];
}

- (NSNumber *)myAge
{
    NSNumber *myAge = [_userDefaults objectForKey:kAgeLimitFilterMyAgeKey];
    return myAge;
}

- (void)setMyAge:(NSNumber *)myAge
{
    if ([myAge isEqualToNumber:@0]) {
        myAge = nil;
    }
    [_userDefaults setObject:myAge forKey:kAgeLimitFilterMyAgeKey];
}


#pragma mark - Price filter

- (PriceFilter)priceFilter
{
    NSNumber *priceFilter = [_userDefaults objectForKey:kPriceFilterSelectionKey];
    if (priceFilter == nil) {
        return PriceFilterShowAllEvents;
    }
    
    return [priceFilter integerValue];
}

- (void)setPriceFilter:(PriceFilter)priceFilter
{
    [_userDefaults setObject:@(priceFilter) forKey:kPriceFilterSelectionKey];
}


// TODO: Where to put this code?
//// Register defaults
//NSArray *allCategories = [ManagedEvent categoryIDs];
//NSDictionary *defaults = @{ kCategoryFilterSelectionKey : allCategories };
//[userDefaults registerDefaults:defaults];
//
//// Load selected categories
//NSArray *selectedCategories = [userDefaults objectForKey:kCategoryFilterSelectionKey];
//_selectedCategories = [NSMutableSet setWithArray:selectedCategories];

@end
