//
//  PageContext.h
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "Context.h"

@interface ManipulationContext : Context

@property (nonatomic, strong) NSString *bookTitle;

@property (nonatomic, strong) NSString *chapterTitle;
@property (nonatomic, assign) NSInteger chapterNumber;

@property (nonatomic, strong) NSString *pageLanguage;
@property (nonatomic, strong) NSString *pageMode;
@property (nonatomic, assign) NSInteger pageNumber;

@property (nonatomic, assign) NSInteger sentenceNumber;
@property (nonatomic, strong) NSString *sentenceText;
@property (nonatomic, assign) BOOL manipulationSentence;

@property (nonatomic, assign) NSInteger stepNumber;

@property (nonatomic, assign) NSInteger ideaNumber;

@end
