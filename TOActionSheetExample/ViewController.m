
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
    actionSheet.title = nil;
    actionSheet.style = (sender == self.darkButton) ? TOActionSheetStyleDark : TOActionSheetStyleLight;
    actionSheet.buttonBackgroundColor = [UIColor clearColor];
    actionSheet.buttonTappedBackgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
    actionSheet.cancelButtonBackgroundColor = [UIColor whiteColor];
    actionSheet.cancelButtonTappedBackgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
    actionSheet.cancelButtonTextColor = [UIColor lightGrayColor];
    actionSheet.cancelButtonTappedTextColor = [UIColor darkGrayColor];
    actionSheet.shadowRadius = 16.0;
    
    NSTextAttachment *attacment = [NSTextAttachment new];
    attacment.image = [UIImage imageNamed:@"play"];
    attacment.bounds = CGRectMake(0, 0, 10, 12);
    
    NSMutableAttributedString *phone1Atrr = (NSMutableAttributedString *)[NSMutableAttributedString attributedStringWithAttachment:attacment];
    [phone1Atrr appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"  12332233" attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}]];
    [phone1Atrr appendAttributedString:[[NSAttributedString alloc] initWithString:@" (custom Service)" attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}]];
    
    [actionSheet addButtonWithAttibuteStr:phone1Atrr icon:nil tappedBlock:^{
        NSLog(@"Done1!");
    }];
    [actionSheet addButtonWithAttibuteStr:phone1Atrr icon:nil tappedBlock:^{
        NSLog(@"Done2!");
    }];

    actionSheet.actionSheetDismissedBlock = ^{
        NSLog(@"Dismissed!");
    };
    UIButton *button = (UIButton *)sender;
    [actionSheet showFromView:button inView:self.navigationController.view];
}

@end
