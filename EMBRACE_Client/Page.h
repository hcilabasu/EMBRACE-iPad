//
//  Page.h
//  EMBRACE
//
//  Created by Andreea Danielescu on 6/14/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Page : NSObject {
    NSString *pagePath; //The hmtl file associated with this page.
    NSString* pageId; //the id assocated with this page. 
}

@property (nonatomic, strong) NSString* pagePath;
@property (nonatomic, strong) NSString* pageId;

@end
