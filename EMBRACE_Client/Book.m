//
//  Book.m
//  eBookReader
//
//  Created by Andreea Danielescu on 2/6/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Book.h"

@implementation Book

@synthesize title;
@synthesize author;

@synthesize coverImagePath;
@synthesize mainContentPath;
@synthesize bookPath;

@synthesize bookItems;
@synthesize itemOrder;

@synthesize chapters;

@synthesize model;

- (id) initWithTitleAndAuthor:(NSString*)path :(NSString*)bookTitle :(NSString*)bookAuthor {
    if (self = [super init]) {
        bookPath = path;
        title = bookTitle;
        author = bookAuthor;
        coverImagePath = nil;
        chapters = [[NSMutableArray alloc] init];
        model = [[InteractionModel alloc] init];
    }
    
    return self;
}

//Get the filepath of the page at pageNum.
-(NSString*) getPageAt:(int)pageNum {
    if(pageNum < [itemOrder count]) {
        NSString* idPage = [itemOrder objectAtIndex:pageNum];
        NSString* page = [bookItems objectForKey:idPage];
    
        //NSString* filepath = [self.bookPath stringByAppendingString:@"/epub/"];
        //filepath = [filepath stringByAppendingString:page];
        
        NSLog(@"in get page at");
        
        NSString* filepath = [self.mainContentPath stringByAppendingString:page];
        
        //NSLog(@"filepath: %@", filepath);
    
        return filepath;
    }
    return nil;
}

-(NSString*) getPageForChapter:(NSString*)chapterTitle {
    //Find the chapter so we can get the chapter ID. 
    for(Chapter* chapter in chapters) {
        if([[chapter title] isEqualToString:chapterTitle]) {
            NSString* chapterId = [chapter chapterId];
            NSString* page = [bookItems objectForKey:chapterId];
            
            if(page == nil) {
                NSLog(@"could not find page");
                return nil;
            }
            else {
                NSString* filepath = [self.mainContentPath stringByAppendingString:page];
            
                return filepath;
            }
        }
    }
    
    return nil; //Didn't find the chapter.
}

- (NSInteger)getPageNumForChapter:(NSString*) chapterTitle {
    
    return -1;
}

//This is the base URL for the book.
- (NSString*) getHTMLURL {
    NSLog(@"in getHTMLURL");
    NSString* idPage = [itemOrder objectAtIndex:0];
    NSString* page = [bookItems objectForKey:idPage];
    NSString* url = [self.mainContentPath stringByAppendingString:page];
    //NSString* url=[[NSBundle mainBundle] resourceURL];
    return url;
}

//Return total number of pages. 
-(NSInteger) totalPages {
    return [itemOrder count];
}

-(void) addChapter:(Chapter*)chapter {
    [chapters addObject:chapter];
}

-(NSString*) getNextPageForChapterAndActivity:(NSString*)chapterTitle :(Mode) activity :(NSString*) currentPage{
    for(Chapter* chapter in chapters) {
    //for(int i = 0; i < [chapters count]; i ++) {
    //    Chapter* chapter = [chapters objectAtIndex:i];
   
        if([[chapter title] isEqualToString:chapterTitle]) {
            return [chapter getNextPageForMode:activity :currentPage];
            //NSString* nextPage = [chapter getNextPageForMode:activity :currentPage];
            
            //if(nextPage != nil) //If this chapter has a next page for this activity, then return it.
            //    return nextPage;
            //else if(i < [chapters count] - 1)//Otherwise, go to the next chapter if there is a next chapter.
            //    return [self getNextPageForChapterAndActivity:[[chapters objectAtIndex:i + 1] title] :activity :nil];
        }
    }
    
    return nil; //Didn't a next page at all.
}

-(NSString* ) getChapterAfterChapter:(NSString* )chapterTitle {
    for(int i = 0; i < [chapters count] - 1; i ++) {
        Chapter* chapter = [chapters objectAtIndex:i];
        
        if([[chapter title] isEqualToString:chapterTitle])
            return [[chapters objectAtIndex:i + 1] title];
    }
    
    return nil; //These is no chapter after this one.
}

@end
