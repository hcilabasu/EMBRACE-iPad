//
//  ITSController.h
//  EMBRACE
//
//  Created by Jithin on 6/1/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ManipulationContext.h"
#import "ActionStep.h"
#import "Book.h"

@class SkillSet;

typedef NS_ENUM(NSInteger, EMComplexity) {
    EM_Easy = 1,
    EM_Medium,
    EM_Complex,
    EM_Default
};

@interface ITSController : NSObject

+ (ITSController *)sharedInstance;
+ (void)resetSharedInstance;

- (void)setAnalyzerDelegate:(id)delegate;

- (SkillSet *)getSkillSet;
- (void)setSkillSet:(SkillSet *)skillSet;

- (void)movedObjectIDs:(NSMutableSet *)movedObjectIDs destinationIDs:(NSArray *)destinationIDs isVerified:(BOOL)verified actionStep:(ActionStep *)actionStep manipulationContext:(ManipulationContext *)context forSentence:(NSString *)sentence withWordMapping:(NSDictionary *)mapDict;

- (void)userDidPlayWord:(NSString *)word context:(ManipulationContext *)context;

- (void)userDidVocabPreviewWord:(NSString *)word context:(ManipulationContext *)context;



- (EMComplexity)getCurrentComplexity;
- (void)setCurrentComplexity;

- (NSMutableSet *)getExtraIntroductionVocabularyForChapter:(Chapter *)chapter inBook:(Book *)book;

- (NSString *)getMostProbableErrorType;

@end
