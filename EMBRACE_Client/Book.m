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
    
        NSString* filepath = [self.mainContentPath stringByAppendingString:page];
        
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

//This is the base URL for the book.
- (NSString*) getHTMLURL {
    NSString* idPage = [itemOrder objectAtIndex:0];
    NSString* page = [bookItems objectForKey:idPage];
    NSString* url = [self.mainContentPath stringByAppendingString:page];
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
        if([[chapter title] isEqualToString:chapterTitle]) {
            return [chapter getNextPageForMode:activity :currentPage];
        }
    }
    
    return nil; //No page after this one..
}

-(NSString* ) getChapterAfterChapter:(NSString* )chapterTitle {
    for(int i = 0; i < [chapters count] - 1; i ++) {
        Chapter* chapter = [chapters objectAtIndex:i];
        
        if([[chapter title] isEqualToString:chapterTitle])
            return [[chapters objectAtIndex:i + 1] title];
    }
    
    return nil; //These is no chapter after this one.
}

-(Chapter* ) getChapterWithTitle:(NSString* )chapterTitle {
    for(Chapter* chapter in chapters) {
        //Chapter title matches setup story title
        if ([[chapter title] isEqualToString:chapterTitle]) {
            return chapter;
        }
    }
    return nil;
}

@end
