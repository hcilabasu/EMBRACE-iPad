//
//  IMViewController.m
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 6/5/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "IMViewController.h"

@implementation IMViewController {
    NSUInteger totalPages; //Total number of chapters/pages in this activity.
    NSUInteger pageNum; //The current chapter/page.

    NSUInteger currentSentence; //Active sentence to be completed.
    NSUInteger totalSentences; //Total number of sentences on this page.

    NSString* movingObjectId; //Object currently being moved.
    NSString* separatingObjectId; //Object identified when pinch gesture performed.
    BOOL movingObject; //True if an object is currently being moved, false otherwise.
    BOOL sepearatingObject; //True if two objects are currently being ungrouped, false otherwise.

    BOOL pinching;

    CGPoint delta; //distance between the top-left corner of the image being moved and the point clicked.
    }

    @property (nonatomic, strong) IBOutlet UIWebView *bookView;

@end

@end
