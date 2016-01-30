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
#import "ConditionSetup.h"

@interface EBookImporter : NSObject

- (NSMutableArray *)importLibrary;
- (Book *)getBookWithTitle:(NSString *)bookTitle;

@end
