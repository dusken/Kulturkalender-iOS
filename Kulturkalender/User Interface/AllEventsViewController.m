//
//  AllEventsViewController.m
//  Kulturkalender
//
//  Created by Christian Rasmussen on 02.10.12.
//  Copyright (c) 2012 Under Dusken. All rights reserved.
//

#import "AllEventsViewController.h"


#pragma mark - Constants

enum {
    kAllEventsSegmentedControllIndex = 0,
    kPaidEventsSegmentedControllIndex = 1,
    kFreeEventsSegmentedControllIndex = 2
};

@implementation AllEventsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Hide search bar as default
    self.tableView.contentOffset = CGPointMake(0.0, self.tableView.tableHeaderView.bounds.size.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - AbstractEventsViewController

- (NSPredicate *)predicate
{
    NSPredicate *predicate = [super predicate];
    
    switch ([self.priceFilterSegmentedControl selectedSegmentIndex]) {
        case kPaidEventsSegmentedControllIndex: {
            NSPredicate *paidPredicate = [NSPredicate predicateWithFormat:@"price > 0"];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ predicate, paidPredicate ]];
            
            break;
        }
        case kFreeEventsSegmentedControllIndex: {
            NSPredicate *freePredicate = [NSPredicate predicateWithFormat:@"price == 0"];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ predicate, freePredicate ]];
            
            break;
        }
    }
    
    return predicate;
}

- (NSString *)cacheName
{
    return @"AllEventsCache";
}


#pragma mark - IBAction

- (IBAction)changePriceFilter:(id)sender
{
    [self reloadPredicate];
    [self updatePlaceholderInSearchField];
}


#pragma mark - Private methods

- (void)updatePlaceholderInSearchField
{
    self.searchDisplayController.searchBar.placeholder = [self searchFieldPlaceholder];
}

- (NSString *)searchFieldPlaceholder
{
    // TODO: Fix localization
    switch ([self.priceFilterSegmentedControl selectedSegmentIndex]) {
        case kAllEventsSegmentedControllIndex:
        {
            return NSLocalizedString(@"Search All Events", nil);
//            return NSLocalizedStringWithDefaultValue(@"ALL_EVENTS_SEARCH_FIELD_PLACEHOLDER", @"", @"", @"Search All Events", @"Placeholder in search field");
        }
        case kPaidEventsSegmentedControllIndex:
        {
            return NSLocalizedString(@"Search Paid Events", nil);
//            return NSLocalizedStringWithDefaultValue(@"PAID_EVENTS_SEARCH_FIELD_PLACEHOLDER", nil, nil, @"Search Paid Events", @"Placeholder in search field");
        }
        case kFreeEventsSegmentedControllIndex:
        {
            return NSLocalizedString(@"Search Free Events", nil);
//            return NSLocalizedStringWithDefaultValue(@"FREE_EVENTS_SEARCH_FIELD_PLACEHOLDER", nil, nil, @"Search Free Events", @"Placeholder in search field");
        }
    }
    
    return nil;
}

@end