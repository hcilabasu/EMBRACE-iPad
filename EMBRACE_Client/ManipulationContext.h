//
//  PageContext.h
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"

@interface ManipulationContext : Context

@property (nonatomic, copy) NSString *bookTitle;

@property (nonatomic, copy) NSString *chapterTitle;
@property (nonatomic, assign) NSInteger chapterNumber;

@property (nonatomic, copy) NSString *pageLanguage;
@property (nonatomic, copy) NSString *pageMode;
@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) NSInteger pageComplexity;

@property (nonatomic, assign) NSInteger sentenceNumber;
@property (nonatomic, assign) NSInteger sentenceComplexity;
@property (nonatomic, copy) NSString *sentenceText;
@property (nonatomic, assign) BOOL manipulationSentence;

@property (nonatomic, assign) NSInteger stepNumber;

@property (nonatomic, assign) NSInteger ideaNumber;

@end
