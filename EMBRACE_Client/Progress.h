//
//  Progress.h
//  EMBRACE
//
//  Created by Administrator on 11/15/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

//Student's current status on a book or chapter
typedef enum Status {
    COMPLETED,
    IN_PROGRESS,
    INCOMPLETE,
    NO_STATUS
} Status;

@interface Progress : NSObject {
    //Maps book titles to arrays of chapters with the specified status
    NSMutableDictionary* chaptersCompleted;
    NSMutableDictionary* chaptersInProgress;
    NSMutableDictionary* chaptersIncomplete;
}

@property (nonatomic, strong) NSMutableDictionary* chaptersCompleted;
@property (nonatomic, strong) NSMutableDictionary* chaptersInProgress;
@property (nonatomic, strong) NSMutableDictionary* chaptersIncomplete;

- (id) init;

- (void) loadBooks:(NSMutableArray*)books;
- (void) setChapters:(NSMutableArray*)chapters fromBook:(NSString*)bookTitle withStatus:(Status)status;

- (Status) getStatusOfBook:(NSString*)bookTitle;

- (Status) getStatusOfChapter:(NSString*)chapterTitle fromBook:(NSString*)bookTitle;
- (void) setStatusOfChapter:(NSString*)chapterTitle :(Status)status fromBook:(NSString*)bookTitle;

@end
