//
//  PageContext.h
//  EMBRACE
//
//  Created by James Rodriguez on 7/21/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"

@interface PageContext : Context

@property (nonatomic, strong) NSString *currentPage; //Current page being shown, so that the next page can be requested
@property (nonatomic, strong) NSString *currentPageId; //Id of the current page being shown
@property (nonatomic, strong) NSString *actualPage; //Stores the address of the current page we are at

@end
