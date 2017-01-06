//
//  ForwardProgress.h
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"

@interface ForwardProgress : Context

@property (nonatomic, strong) NSString *bookTitle;

@property (nonatomic, strong) NSString *chapterTitle;
@property (nonatomic, assign) NSInteger chapterNumber;

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, strong) NSString *pageId; //Id of the current page being shown

@property (nonatomic, assign) NSInteger sentenceNumber;

@property (nonatomic, assign) NSInteger stepNumber;

@property (nonatomic, assign) NSInteger ideaNumber;

@end
