//
//  FilterViewController.m
//  Kulturkalender
//
//  Created by Christian Rasmussen on 31.10.12.
//  Copyright (c) 2012 Under Dusken. All rights reserved.
//

#import "FilterViewController.h"
#import "FilterManager.h"

enum {
    kCategorySectionIndex = 0,
    kAgeLimitSectionIndex = 1,
    kMyAgeSectionIndex = 2,
    kPriceSectionIndex = 3
};

@implementation FilterViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateViewInfo];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"disappear");
    [self setMyAge];
}


#pragma mark - IBAction

- (IBAction)myAgeTextFieldDidEndEditing:(id)sender
{
    // FIXME: Fix bug where the age is not set if the filter view is closed while editing the text field
    NSLog(@"End editing");
    [self setMyAge];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kCategorySectionIndex) {
        // TODO: Fix
        return 0;//[[Event categoryIDs] count];
    }
    
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section == kCategorySectionIndex) {
        static NSString *cellIdentifier = @"CategoryCell";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        
        // TODO: Fix
//        NSString *categoryID = [[Event categoryIDs] objectAtIndex:indexPath.row];
//        BOOL isSelected = [self.filterManager isSelectedForCategoryID:categoryID];
//        
//        cell.textLabel.text = [Event stringForCategoryID:categoryID];
//        cell.accessoryType = (isSelected) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        return cell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self hideKeyboard];
    
    // If the row is not selected, selected it, and vice verca
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (indexPath.section) {
        case kCategorySectionIndex: {
            [self setCategoryFilterForCell:cell];
            break;
        }
        case kAgeLimitSectionIndex: {
            [self setAgeLimitFilterForCell:cell];
            break;
        }
        case kPriceSectionIndex: {
            [self setPriceFilterForCell:cell];
            break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 0;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideKeyboard];
}


#pragma mark - Category filter

// TODO: Fix
- (void)updateCategoryFilterSelectedCell
{
//    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//    
//    NSString *categoryID = [[Event categoryIDs] objectAtIndex:indexPath.row];
//    BOOL isSelected = [self.filterManager isSelectedForCategoryID:categoryID];
    
//    cell.accessoryType = (isSelected == YES) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)setCategoryFilterForCell:(UITableViewCell *)cell
{
    // TODO: Fix
//    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//    NSString *categoryID = [[Event categoryIDs] objectAtIndex:indexPath.row];
//    [self.filterManager toggleSelectedForCategoryID:categoryID];
//    
//    [self updateCategoryFilterSelectedCell];
}


#pragma mark - Age limit filter

- (void)updateAgeLimitFilterCells
{
    self.ageLimitAllEventsCell.accessoryType = (self.filterManager.ageLimitFilter == AgeLimitFilterShowAllEvents) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.ageLimitAllowedForMyAgeCell.accessoryType = (self.filterManager.ageLimitFilter == AgeLimitFilterShowAllowedForMyAge) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)setAgeLimitFilterForCell:(UITableViewCell *)cell
{
    if (cell == self.ageLimitAllEventsCell) {
        self.filterManager.ageLimitFilter = AgeLimitFilterShowAllEvents;
    }
    else if (cell == self.ageLimitAllowedForMyAgeCell) {
        self.filterManager.ageLimitFilter = AgeLimitFilterShowAllowedForMyAge;
    }
    
    [self updateAgeLimitFilterCells];
}

- (void)updateMyAgeTextField
{
    if ([self.filterManager.myAge unsignedIntegerValue] > 0) {
        self.myAgeTextField.text = [self.filterManager.myAge stringValue];
    }
}

- (void)setMyAge
{
    NSNumber *myAge = [NSNumber numberWithUnsignedInteger:[self.myAgeTextField.text integerValue]];
    [self.filterManager setMyAge:myAge];
}


#pragma mark - Price filter

- (void)updatePriceFilterCells
{
    self.priceFilterAllEventsCell.accessoryType = (self.filterManager.priceFilter == PriceFilterShowAllEvents) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.priceFilterPaidEvents.accessoryType = (self.filterManager.priceFilter == PriceFilterShowPaidEvents) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.priceFilterFreeEvents.accessoryType = (self.filterManager.priceFilter == PriceFilterShowFreeEvents) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)setPriceFilterForCell:(UITableViewCell *)cell
{
    if (cell == self.priceFilterAllEventsCell) {
        self.filterManager.priceFilter = PriceFilterShowAllEvents;
    }
    else if (cell == self.priceFilterPaidEvents) {
        self.filterManager.priceFilter = PriceFilterShowPaidEvents;
    }
    else if (cell == self.priceFilterFreeEvents) {
        self.filterManager.priceFilter = PriceFilterShowFreeEvents;
    }
    
    [self updatePriceFilterCells];
}


#pragma mark - Private methods

- (void)hideKeyboard
{
    [self.tableView endEditing:YES];
}

- (void)updateViewInfo
{
    [self updateAgeLimitFilterCells];
    [self updateMyAgeTextField];
    [self updatePriceFilterCells];
}



@end
