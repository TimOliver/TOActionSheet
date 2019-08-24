
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
    actionSheet.contentstyle = TOActionSheetContentStyleDefault;
    [actionSheet addButtonWithTitle:@"Do the thing" icon:nil tappedBlock:^{
        NSLog(@"Done!");
    }];
    [actionSheet addButtonWithTitle:@"Do another thing" icon:nil tappedBlock:^{
        NSLog(@"Done!");
    }];
    [actionSheet addDestructiveButtonWithTitle:@"Delete the thing" icon:nil tappedBlock:^{
        NSLog(@"Deleted!");
    }];
    actionSheet.actionSheetDismissedBlock = ^{
        NSLog(@"Dismissed!");
    };
    UIButton *button = (UIButton *)sender;
    [actionSheet showFromView:button inView:self.navigationController.view];
}

@end
