//
//  Readebook.h
//  eBookReader
//
//  Created by Andreea Danielescu on 2/6/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDataXMLNode.h"
#import "ZipArchive.h"
#import "Book.h"

@interface EBookImporter : NSObject {
    NSArray *dirPaths;
    NSString *docsDir;
    NSMutableArray *library;
}

@property (nonatomic,strong) NSString *docsDir;
@property (nonatomic,strong) NSArray *dirPaths;
@property (nonatomic,strong) NSMutableArray *library;

-(NSMutableArray*) importLibrary;
-(Book*) getBookWithTitle:(NSString*) bookTitle;
-(void) readMetadataForBook:(Book*) book;
@end
