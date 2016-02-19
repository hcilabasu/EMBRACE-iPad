//
//  LoginViewController.h
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 6/5/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController {
    IBOutlet UITextField *schoolCodeField;
    IBOutlet UITextField *participantCodeField;
    IBOutlet UITextField *studyDayField;
    IBOutlet UITextField *experimenterField;
}

- (IBAction)login:(id)sender;
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;

@end
