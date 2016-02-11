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
@synthesize currentSequence;
@synthesize sequenceId;

- (id)init {
    chaptersCompleted = [[NSMutableDictionary alloc] init];
    chaptersInProgress = [[NSMutableDictionary alloc] init];
    chaptersIncomplete = [[NSMutableDictionary alloc] init];
    
    //Not using sequence by default
    sequenceId = @"NONE";
    currentSequence = -1;
    
    return self;
}

/*
 * Loads array of books with chapters and sets all chapters to incomplete
 */
- (void)loadBooks:(NSMutableArray *)books {
    for (Book *book in books) {
        NSString *bookTitle = [book title];
        
        NSMutableArray *chapterTitles = [[NSMutableArray alloc] init];
        
        for (Chapter *chapter in [book chapters]) {
            NSString *chapterTitle = [chapter title];
            
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
- (void)loadChapters:(NSMutableArray *)chapters fromBook:(NSString *)bookTitle withStatus:(Status)status {
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
 * Goes through the array of books and adds any new books/chapters as incomplete
 */
- (void)addNewContent:(NSMutableArray *)books {
    NSMutableArray *newBooks = [[NSMutableArray alloc] init]; //holds new books, if any, to be added
    
    for (Book *book in books) {
        NSString *bookTitle = [book title];
        
        Status bookStatus = [self getStatusOfBook:bookTitle];
        
        //Book already exists
        if (bookStatus != NO_STATUS) {
            for (Chapter *chapter in [book chapters]) {
                NSString *chapterTitle = [chapter title];
                
                Status chapterStatus = [self getStatusOfChapter:chapterTitle fromBook:bookTitle];
                
                //Chapter does not exist
                if (chapterStatus == NO_STATUS) {
                    //Add chapter as incomplete
                    NSMutableArray *incompleteChapters = [chaptersIncomplete objectForKey:bookTitle];
                    [incompleteChapters addObject:chapterTitle];
                    [chaptersIncomplete setObject:incompleteChapters forKey:bookTitle];
                }
            }
            
            if (bookStatus != INCOMPLETE) {
                //If a new book was added, it might need to be set as in progress
                [self setNextChapterInProgressForBook:bookTitle];
            }
        }
        //Book does not exist
        else {
            [newBooks addObject:book];
        }
    }
    
    //Add any new books along with their chapters
    if ([newBooks count] > 0) {
        [self loadBooks:newBooks];
    }
}

/*
 * Returns current status of book
 */
- (Status)getStatusOfBook:(NSString *)bookTitle {
    //Check if book exists
    if ([chaptersCompleted objectForKey:bookTitle] != nil) {
        BOOL hasCompletedChapters = [[chaptersCompleted objectForKey:bookTitle] count] > 0;
        BOOL hasInProgressChapters = [[chaptersInProgress objectForKey:bookTitle] count] > 0;
        BOOL hasIncompleteChapters = [[chaptersIncomplete objectForKey:bookTitle] count] > 0;
        
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
    else {
        //Book does not exist
        return NO_STATUS;
    }
}

/*
 * Returns current status of given chapter in book
 */
- (Status)getStatusOfChapter:(NSString *)chapterTitle fromBook:(NSString *)bookTitle {
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
- (void)setStatusOfChapter:(NSString *)chapterTitle :(Status)status fromBook:(NSString *)bookTitle {
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

/*
 * Sets the status of the next incomplete chapter in the specified book to in progress.
 * Returns true if chapter was set or an in progress chapter already exists. Returns false otherwise.
 */
- (BOOL)setNextChapterInProgressForBook:(NSString *)bookTitle {
    //No chapters are in progress
    if ([[chaptersInProgress objectForKey:bookTitle] count] == 0) {
        NSMutableArray *incompleteChapters = [chaptersIncomplete objectForKey:bookTitle];
        
        //Incomplete chapters exist
        if ([incompleteChapters count] > 0) {
            [self setStatusOfChapter:[incompleteChapters objectAtIndex:0] :IN_PROGRESS fromBook:bookTitle];
            
            return true;
        }
        //No incomplete chapters exist, so this book must be completed
        else {
            return false;
        }
    }
    //A chapter is already in progress
    else {
        return true;
    }
}

@end
