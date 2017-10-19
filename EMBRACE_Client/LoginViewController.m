//
//  LoginViewController.m
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 6/5/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "LoginViewController.h"
#import "LibraryViewController.h"
#import "Progress.h"
#import "ServerCommunicationController.h"
#define kOFFSET_FOR_KEYBOARD 120.0

@interface LoginViewController () <UITextFieldDelegate> {
    IBOutlet UITextField *schoolCodeField;
    IBOutlet UITextField *participantCodeField;
    IBOutlet UITextField *studyDayField;
    IBOutlet UITextField *experimenterField;
    BOOL  isViewMoveUp;
    Student *student;
    Progress *studentProgress;
}

@end

@implementation LoginViewController
@synthesize conditionIcon;
@synthesize conditionLabel;
NSString* const DROPBOX_PASSWORD_UNLOCKED = @"hello"; //used to set locked books/chapters to in progress
NSString* const DROPBOX_PASSWORD_LOCKED = @"goodbye"; //used to set locked books/chapters to completed

- (void)viewDidLoad {
    [super viewDidLoad];
    [schoolCodeField setDelegate:self];
    [participantCodeField setDelegate:self];
    [studyDayField setDelegate:self];
    [experimenterField setDelegate:self];
    participantCodeField.tag=1;
    conditionLabel.text=@"";
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    isViewMoveUp=NO;
    [self.view endEditing:YES];
}

- (IBAction)login:(id)sender {
    NSString *schoolCode = [schoolCodeField text];
    NSString *participantCode = [participantCodeField text];
    NSString *studyDay = [studyDayField text];
    NSString *experimenterName = [experimenterField text];
    
    //When student logs in, check that all fields were entered; if they didn't, provide an error message
    if ([schoolCode isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"School Code missing!"
                              message:@"Please enter the School Code."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    else if ([participantCode isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Participant Code missing!"
                              message:@"Please enter the Participant Code."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    else if ([studyDay isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Study Day missing!"
                              message:@"Please enter the Study Day."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    else if ([experimenterName isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Experimenter name missing!"
                              message:@"Please enter Experimenter name."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        
        [alert show];
    }
    else {
        //If they did, then check to see if the student already exists.
        //If student exists, pull up student information.
        //If student doesn't exist, create new student profile.
        //For the moment, assume student does not exist, and create a new student.
        student = [[Student alloc] initWithValues:schoolCode :participantCode :studyDay: experimenterName];
        
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        //NSString *tempFileName = [NSString stringWithFormat:@"%@ %@ %@.txt", schoolCode, participantCode, studyDay];
        //NSString *doesFileExist = [documentsPath stringByAppendingPathComponent:tempFileName];
        //BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:doesFileExist];
        
        //if (fileExists) {
            //Append timestamp
            NSDate *currentTime = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM-dd-yyyy'T'hh:mm.ss.SSS"];
            NSString *timeStampValue = [dateFormatter stringFromDate: currentTime];
            
            [student setCurrentTimestamp:timeStampValue];
        //}
        
        [[ServerCommunicationController sharedInstance] setupStudyContext:student];
        [[ServerCommunicationController sharedInstance] logPressLogin];
        
        if ([[ConditionSetup sharedInstance] allowFileSync]) {
            //NOTE: Still testing this functionality
            //Download progress file from Dropbox
            
            //[[ServerCommunicationController sharedInstance] downloadProgressForStudent:student completionHandler:^(BOOL success) {
            //Path to each directory
            NSString *progressFilePath = [documentsPath stringByAppendingPathComponent:@"ProgressFiles"];
            NSString *currentSessionProgressFilePath = [progressFilePath stringByAppendingPathComponent:@"CurrentSession"];
            NSString *masterProgressFilePath = [progressFilePath stringByAppendingPathComponent:@"Master"];
            NSString *backupProgressFilePath = [progressFilePath stringByAppendingPathComponent:@"Backup"];
            
            //Check if the directory paths actually exist, if they do not, then create the directories
            BOOL isDir;
            NSFileManager *fileManager= [NSFileManager defaultManager];
            if(![fileManager fileExistsAtPath:progressFilePath isDirectory:&isDir])
                if(![fileManager createDirectoryAtPath:progressFilePath withIntermediateDirectories:YES attributes:nil error:NULL])
                    NSLog(@"Error: Create folder failed %@", progressFilePath);
            
            if(![fileManager fileExistsAtPath:currentSessionProgressFilePath isDirectory:&isDir])
                if(![fileManager createDirectoryAtPath:currentSessionProgressFilePath withIntermediateDirectories:YES attributes:nil error:NULL])
                    NSLog(@"Error: Create folder failed %@", currentSessionProgressFilePath);
            
            if(![fileManager fileExistsAtPath:masterProgressFilePath isDirectory:&isDir])
                if(![fileManager createDirectoryAtPath:masterProgressFilePath withIntermediateDirectories:YES attributes:nil error:NULL])
                    NSLog(@"Error: Create folder failed %@", masterProgressFilePath);
            
            if(![fileManager fileExistsAtPath:backupProgressFilePath isDirectory:&isDir])
                if(![fileManager createDirectoryAtPath:backupProgressFilePath withIntermediateDirectories:YES attributes:nil error:NULL])
                    NSLog(@"Error: Create folder failed %@", backupProgressFilePath);
            
           /* assert(fileManager != nil);
            NSError* error = nil;
            
            //Check to see if file exists in CurrentSession, if it does not, then check to see if it's in Master and move it to Current Session
            NSString *doesFileExist = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",currentSessionProgressFilePath,student]];
            if(![[NSFileManager defaultManager] fileExistsAtPath:doesFileExist]){
                
                doesFileExist = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",masterProgressFilePath,student]];
                
                if([[NSFileManager defaultManager] fileExistsAtPath:doesFileExist]){
                    //Move file from CurrentSession to Backup folder
                    [fileManager moveItemAtPath:[NSString stringWithFormat:@"%@/%@",masterProgressFilePath,student] toPath:[NSString stringWithFormat:@"%@/%@",currentSessionProgressFilePath,student] error:&error];
                }
            }}*/
            
            //Load progress for student if it exists
                studentProgress = [[ServerCommunicationController sharedInstance] loadProgress:student];
            
            // Load skills for student if available
            SkillSet *skillSet = [[ServerCommunicationController sharedInstance] loadSkills:student];
            
            if (skillSet != nil) {
                [[ITSController sharedInstance] setSkillSet:skillSet];
            }
            
                //Then take the user to the library view.
                [self performSegueWithIdentifier: @"OpenLibrarySegue" sender: self];
            //}];
        }
        else {
            //Load progress for student if it exists
            studentProgress = [[ServerCommunicationController sharedInstance] loadProgress:student];
            
            // Load skills for student if available
            SkillSet *skillSet = [[ServerCommunicationController sharedInstance] loadSkills:student];
            
            if (skillSet != nil) {
                [[ITSController sharedInstance] setSkillSet:skillSet];
            }
            
            //Then take the user to the library view.
            [self performSegueWithIdentifier: @"OpenLibrarySegue" sender: self];
        }
    }
}

/*
 * Displays prompt to enter password to unlock dropboxbuttons
 */
- (IBAction)showPasswordPrompt:(id)sender {
    UIAlertView *passwordPrompt = [[UIAlertView alloc] initWithTitle:@"Password" message:@"Enter password to lock/unlock dropbox" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    passwordPrompt.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [passwordPrompt show];
}

/*
 * Checks if user input for password prompt is correct to unlock the selected book or chapter
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView title] isEqualToString:@"Password"] && buttonIndex == 1) {
        
        //Password is correct for unlocking dropbox buttons
        if ([[[alertView textFieldAtIndex:0] text] isEqualToString:DROPBOX_PASSWORD_UNLOCKED]) {
            NSArray *arrSubviews = [self.view subviews];
            for(UIView *tmpView in arrSubviews)
            {
                if([tmpView isMemberOfClass:[UIButton class]])
                {
                    if(tmpView.tag == 4) {
                        [tmpView setHidden: false];
                    }
                    
                    if(tmpView.tag == 5) {
                        [tmpView setHidden: false];
                    }
                }
            }
        }
        //Password is correct for locking dropbox buttons
        else if ([[[alertView textFieldAtIndex:0] text] isEqualToString:DROPBOX_PASSWORD_LOCKED]) {
            NSArray *arrSubviews = [self.view subviews];
            for(UIView *tmpView in arrSubviews)
            {
                if([tmpView isMemberOfClass:[UIButton class]])
                {
                    if(tmpView.tag == 4) {
                        [tmpView setHidden: true];
                    }
                    
                    if(tmpView.tag == 5) {
                        [tmpView setHidden: true];
                    }
                }
            }
        }
    }
}

- (IBAction)uploadProgress:(id)sender {
    if ([[ConditionSetup sharedInstance] allowFileSync]) {
        [[ServerCommunicationController sharedInstance] uploadFilesForStudent:student completionHandler:^(BOOL success) {
            //successfully uploaded files to Dropbox
        }failure:^(BOOL failure){
            //Failed to upload progress files to Dropbox
        }];
    }
}

- (IBAction)downloadProgress:(id)sender {
    if ([[ConditionSetup sharedInstance] allowFileSync]) {
        [[ServerCommunicationController sharedInstance] downloadProgressForStudent:student completionHandler:^(BOOL success) {
            //Load progress for student if it exists
            studentProgress = [[ServerCommunicationController sharedInstance] loadProgress:student];
        }failure:^(BOOL failure){
            //Failed to download progress files from Dropbox
        }];
    }
}



- (void)textFieldDidEndEditing:(UITextField *)textField {
    //Trim whitespace from textfield input
    textField.text = [[textField text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if(1==textField.tag){
        BOOL isCorrect= [self isConditionInputCorrect:textField];
        UIImage * img = [UIImage imageNamed: @"warningIcon.png"];
        if(isCorrect){
            img = [UIImage imageNamed: @"correctIcon"];
        }
        img=[self imageWithImage:img scaledToSize:CGSizeMake(30, 30)];
        conditionIcon.image=img;
    }
}



-(BOOL)isConditionInputCorrect:(UITextField *)textField {
    NSString* textString=textField.text;
    textString=textField.text = [textString stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]];
    
    int numSequences = 4;
    
    NSString* ITSstring=  [textString substringToIndex:3];
    ITSstring= [ITSstring uppercaseString];
    if(![ITSstring isEqualToString:@"ITS"]){
        return NO;
    }
    
    NSArray* ary=[textString componentsSeparatedByString:@"ITS"];
    
    if([textString componentsSeparatedByString:@"ITS"].count>0){
        NSInteger sequenceNumber = [[textString componentsSeparatedByString:@"ITS"][1] integerValue] % numSequences;
        if(sequenceNumber>0){
            return YES;
        }else{
            return NO;
        }

    }else{
        return 0;
    }
}

-(UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

/*
 * Segue prep to go from LoginViewController to LibraryViewController.
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    LibraryViewController *destination = [segue destinationViewController];
    
    destination.student = student;
    destination.studentProgress = studentProgress;
}






/*
 * checking if the keyboard everlays with the text box
*/
-(void)keyboardWillShow {
    if(isViewMoveUp){
        return;
    }
    [self setViewMovedUp:YES];
    isViewMoveUp=YES;

}

-(void)keyboardWillHide {
    if(isViewMoveUp){
        [self setViewMovedUp:NO];
        isViewMoveUp=NO;
    }
}



//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}
@end
