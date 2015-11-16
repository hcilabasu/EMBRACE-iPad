//
//  Progress.m
//  EMBRACE
//
//  Created by Administrator on 11/15/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import "Progress.h"
#import "Book.h"

@implementation Progress

@synthesize chaptersCompleted;
@synthesize chaptersInProgress;
@synthesize chaptersIncomplete;

- (id) init {
    chaptersCompleted = [[NSMutableDictionary alloc] init];
    chaptersInProgress = [[NSMutableDictionary alloc] init];
    chaptersIncomplete = [[NSMutableDictionary alloc] init];
    
    return self;
}

/*
 * Loads array of books with chapters and sets all chapters to incomplete
 */
- (void) loadBooks:(NSMutableArray*)books {
    for (Book* book in books) {
        NSString* bookTitle = [book title];
        
        NSMutableArray* chapterTitles = [[NSMutableArray alloc] init];
        
        for (Chapter* chapter in [book chapters]) {
            NSString* chapterTitle = [chapter title];
            
            [chapterTitles addObject:chapterTitle];
        }
        
        //Start off with no chapters that are completed or in progress
        [chaptersCompleted setObject:[[NSMutableArray alloc] init] forKey:bookTitle];
        [chaptersInProgress setObject:[[NSMutableArray alloc] init] forKey:bookTitle];
        
        //And start off with all chapters incomplete
        [chaptersIncomplete setObject:chapterTitles forKey:bookTitle];
    }
}

/*
 * Sets array of chapter titles from a book with the given status
 */
- (void) setChapters:(NSMutableArray*)chapters fromBook:(NSString*)bookTitle withStatus:(Status)status {
    if (status == COMPLETED) {
        [chaptersCompleted setObject:chapters forKey:bookTitle];
    }
    else if (status == IN_PROGRESS) {
        [chaptersInProgress setObject:chapters forKey:bookTitle];
    }
    else if (status == INCOMPLETE) {
        [chaptersIncomplete setObject:chapters forKey:bookTitle];
    }
}

/*
 * Returns current status of book
 */
- (Status) getStatusOfBook:(NSString*)bookTitle {
    BOOL hasCompletedChapters = ![[chaptersCompleted objectForKey:bookTitle] isEmpty];
    BOOL hasInProgressChapters = ![[chaptersInProgress objectForKey:bookTitle] isEmpty];
    BOOL hasIncompleteChapters = ![[chaptersIncomplete objectForKey:bookTitle] isEmpty];
    
    //All chapters of book are completed
    if (hasCompletedChapters && !hasInProgressChapters && !hasIncompleteChapters) {
        return COMPLETED;
    }
    //All chapters of book are incomplete
    else if (!hasCompletedChapters && !hasInProgressChapters && hasIncompleteChapters) {
        return INCOMPLETE;
    }
    //Chapters of book may be completed, in progress, or incomplete
    else {
        return IN_PROGRESS;
    }
}

/*
 * Returns current status of given chapter in book
 */
- (Status) getStatusOfChapter:(NSString*)chapterTitle fromBook:(NSString*)bookTitle {
    if ([[chaptersCompleted objectForKey:bookTitle] containsObject:chapterTitle]) {
        return COMPLETED;
    }
    else if ([[chaptersInProgress objectForKey:bookTitle] containsObject:chapterTitle]) {
        return IN_PROGRESS;
    }
    else if ([[chaptersIncomplete objectForKey:bookTitle] containsObject:chapterTitle]) {
        return INCOMPLETE;
    }
    else {
        //Chapter was not found
        return NO_STATUS;
    }
}

/*
 * Sets status of given chapter in book to the specified status
 */
- (void) setStatusOfChapter:(NSString*)chapterTitle :(Status)status fromBook:(NSString*)bookTitle {
    Status currentStatus = [self getStatusOfChapter:chapterTitle fromBook:bookTitle];
    
    //Remove chapter's current status
    if (currentStatus == COMPLETED) {
        [[chaptersCompleted objectForKey:bookTitle] removeObject:chapterTitle];
    }
    else if (currentStatus == IN_PROGRESS) {
        [[chaptersInProgress objectForKey:bookTitle] removeObject:chapterTitle];
    }
    else if (currentStatus == INCOMPLETE) {
        [[chaptersIncomplete objectForKey:bookTitle] removeObject:chapterTitle];
    }
    
    //Set chapter's new status
    if (status == COMPLETED) {
        [[chaptersCompleted objectForKey:bookTitle] addObject:chapterTitle];
    }
    else if (status == IN_PROGRESS) {
        [[chaptersInProgress objectForKey:bookTitle] addObject:chapterTitle];
    }
    else if (status == INCOMPLETE) {
        [[chaptersIncomplete objectForKey:bookTitle] addObject:chapterTitle];
    }
}

@end
