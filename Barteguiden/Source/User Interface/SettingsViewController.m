//
//  SettingsViewController.m
//  Barteguiden
//
//  Created by Christian Rasmussen on 01.11.12.
//  Copyright (c) 2012 Under Dusken. All rights reserved.
//

#import "SettingsViewController.h"
#import "CalendarManager.h"
#import "AlertChooser.h"
#import "CalendarTransformers.h"


@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateViewInfo];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    if (cell == self.defaultCalendarCell) {
        [self navigateToCalendarChooser];
    }
    else if (cell == self.defaultAlertCell) {
        [self navigateToAlertChooser];
    }
    else if (cell == self.sendUsYourTipsCell) {
        [self presentSendUsYourTips];
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


#pragma mark - IBAction

- (IBAction)toggleAutoAddFavorites:(UISwitch *)sender
{
    [self.calendarManager setAutoAddFavorites:sender.on];
}


#pragma mark - EKCalendarChooserDelegate

- (void)calendarChooserSelectionDidChange:(EKCalendarChooser *)calendarChooser
{
    self.calendarManager.defaultCalendar = [calendarChooser.selectedCalendars anyObject];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - DefaultAlertViewControllerDelegate

- (void)alertChooserSelectionDidChange:(AlertChooser *)alertChooser
{
    self.calendarManager.defaultAlert = alertChooser.selectedAlert;
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - Private methods

- (void)updateViewInfo
{
    self.autoAddFavoritesSwitch.on = [self.calendarManager shouldAutoAddFavorites];
    self.defaultCalendarLabel.text = [[self.calendarManager defaultCalendar] title];
    NSValueTransformer *alertDescription = [NSValueTransformer valueTransformerForName:CalendarAlertDescriptionTransformerName];
    self.defaultAlertLabel.text = [alertDescription transformedValue:[self.calendarManager defaultAlert]];
}

- (void)navigateToCalendarChooser
{
    EKCalendarChooser *calendarChooser = [[EKCalendarChooser alloc] initWithSelectionStyle:EKCalendarChooserSelectionStyleSingle displayStyle:EKCalendarChooserDisplayWritableCalendarsOnly entityType:EKEntityTypeEvent eventStore:self.calendarManager.calendarStore];
    calendarChooser.delegate = self;
    calendarChooser.selectedCalendars = [NSSet setWithObject:[self.calendarManager defaultCalendar]];
    calendarChooser.title = NSLocalizedString(@"Default Calendar", nil);
    [self.navigationController pushViewController:calendarChooser animated:YES];
}

- (void)navigateToAlertChooser
{
    AlertChooser *alertChooser = [[AlertChooser alloc] init];
    alertChooser.delegate = self;
    alertChooser.selectedAlert = [self.calendarManager defaultAlert];
    alertChooser.title = NSLocalizedString(@"Default Alert", nil);
    [self.navigationController pushViewController:alertChooser animated:YES];
}

- (void)presentSendUsYourTips
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        // FIXME: Update these values
        NSString *subject = NSLocalizedString(@"Tips for Barteguiden", nil);
        [mailViewController setToRecipients:@[@"tips@underdusken.no"]];
        [mailViewController setSubject:subject];
        
        [self presentViewController:mailViewController animated:YES completion:NULL];
    }
    else {
        // TODO: Handle error
    }
}

@end
