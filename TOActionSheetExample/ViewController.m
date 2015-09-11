
//
//  ViewController.m
//  TOActionSheetExample
//
//  Created by Tim Oliver on 9/1/15.
//  Copyright (c) 2015 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TOActionSheet.h"

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)didTapShow:(id)sender {
    TOActionSheet *actionSheet = [[TOActionSheet alloc] init];
    actionSheet.title = @"A thing needs to be done.\nAre you sure you want to do it?";
    actionSheet.style = (sender == self.darkButton) ? TOActionSheetStyleDark : TOActionSheetStyleLight;
    [actionSheet addButtonWithTitle:@"Do the thing" tappedBlock:^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Done!" message:@"The thing was done!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay!", nil];
        [alertView show];
    }];
    [actionSheet addButtonWithTitle:@"Do another thing" tappedBlock:^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Done!" message:@"The other thing was done!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay!", nil];
        [alertView show];
    }];
    [actionSheet addDestructiveButtonWithTitle:@"Delete the thing" tappedBlock:^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Deleted!" message:@"The thing was deleted!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay!", nil];
        [alertView show];
    }];
    
    UIButton *button = (UIButton *)sender;
    [actionSheet showFromView:button inView:self.navigationController.view];
}

@end
