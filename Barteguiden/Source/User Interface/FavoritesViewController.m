//
//  FavoritedEventsViewController.m
//  Barteguiden
//
//  Created by Christian Rasmussen on 02.10.12.
//  Copyright (c) 2012 Under Dusken. All rights reserved.
//

#import "FavoritesViewController.h"
#import "EventKit.h"
#import "EventKitUI.h"


@implementation FavoritesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // WORKAROUND: Placeholder text and segmented control text is not retrieved from localization in iOS6
    // http://stackoverflow.com/questions/15075165/storyboard-base-localization-strings-file-does-not-localize-at-runtime
    self.searchDisplayController.searchBar.placeholder = NSLocalizedStringWithDefaultValue(@"FAVORITES_SEARCH_FIELD_PLACEHOLDER", nil, [NSBundle mainBundle], @"Search Favorites", @"Placeholder text in search field in favorites tab");
    
    // Enable editing of favorites
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - AbstractEventsViewController

- (NSPredicate *)eventsPredicate
{
    // NOTE: Does not call [super eventsPredicate] to allow old events to show in this list
    
    NSPredicate *favoritesPredicate = [self.eventStore predicateForFavoritedEvents];
    
    return favoritesPredicate;
}


#pragma mark - UITableViewDataSource

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Remove favorite flag
        id<Event> event = [self.eventResultsController eventForIndexPath:indexPath];
        [event setFavorite:NO];
    }
}


#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedStringWithDefaultValue(@"FAVORITES_REMOVE_BUTTON", nil, [NSBundle mainBundle], @"Remove", @"Title of button to remove an event from favorites");
}

@end
