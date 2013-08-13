//
//  LoginViewController.m
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 6/5/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "LoginViewController.h"
#import "LibraryViewController.h"
@interface LoginViewController () {
    Student *student;
}

@end

@implementation LoginViewController

-(IBAction)login:(id)sender {
    //When student presses login, we need to check and make sure they entered a first and last name.
    NSString* firstName = [firstNameField text];
    NSString* lastName = [lastNameField text];
    
    //If they didn't, provide an error message.
    if([firstName isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"First name missing!"
                              message:@"Please enter your first name."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    else if([lastName isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Last name missing!"
                              message:@"Please enter your last name."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    else {
        NSLog(@"name: %@ %@", firstName, lastName);
        //If they did, then check to see if the student already exists.
        //If student exists, pull up student information.
        //If student doesn't exist, create new student profile.
        //For the moment, assume student does not exist, and create a new student.
        student = [[Student alloc] initWithName:firstName :lastName];

        //Then take the user to the library view.
        [self performSegueWithIdentifier: @"OpenLibrarySegue" sender: self];
    }
}

//Segue prep to go from LoginViewController to LibraryViewController.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    LibraryViewController *destination = [segue destinationViewController];
    
    destination.student = student;    
}
@end
