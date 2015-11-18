//
//  LibraryViewController.h
//  eBookReader
//
//  Created by Andreea Danielescu on 1/23/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EbookImporter.h"
#import "Book.h"
#import "Student.h"
#import "Progress.h"

@interface LibraryViewController : UIViewController {
    EBookImporter *bookImporter;
    NSMutableArray* books;
    
    Student *student;
    Progress* studentProgress;
    Mode currentMode;
    
    IBOutlet UIBarButtonItem *booksButton;
}

@property (strong, nonatomic) id dataObject;
@property (nonatomic, strong) Student* student;
@property (nonatomic, strong) Progress* studentProgress;

@end
