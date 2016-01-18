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
    NSString* experimenter = [experimenterField text];
    NSString* school = [schoolField text];
    
    //If they didn't, provide an error message.
    if([school isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"School Code missing!"
                              message:@"Please enter the School Code."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    else if([firstName isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Participant Code missing!"
                              message:@"Please enter the Participant Code."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    else if([lastName isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Study Day missing!"
                              message:@"Please enter the Study Day."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    else if([experimenter isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Experimenter name missing!"
                              message:@"Please enter Experimenter name."
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
        
        student = [[Student alloc] initWithName: school:firstName :lastName: experimenter];
        
        NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* tempFileName = [NSString stringWithFormat:@"%@ %@ %@.txt",school, firstName, lastName];
        NSString* doesFileExist = [documentsPath stringByAppendingPathComponent:tempFileName];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:doesFileExist];
        
        if(fileExists)
        {
            //append timestamp
            //timestamp
            NSDate *currentTime = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM-dd-yyyy'T'hh:mm.ss.SSS"];
            NSString *timeStampValue = [dateFormatter stringFromDate: currentTime];
            
            [student setCurrentTimestamp:timeStampValue];
        }

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
