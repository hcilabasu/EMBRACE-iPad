//
//  IMViewController.h
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 6/5/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EbookImporter.h"
#import "Book.h"

@interface IMViewController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate> {
    EBookImporter *bookImporter;
    Book* book;
}

@property (nonatomic, strong) EBookImporter *bookImporter;
@property (nonatomic, strong) NSString *bookTitle;
@property (nonatomic, strong) Book* book;

-(void) loadFirstPage;

@end
