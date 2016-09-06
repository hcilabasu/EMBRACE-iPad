//
//  Chapter.h
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 6/5/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhysicalManipulationActivity.h"
#import "ImagineManipulationActivity.h"
#import "ScriptAudio.h"

typedef enum VocabularyType {
    VOCAB_NONE, // No type
    VOCAB_INTRO, // Word is introduced in the chapter (may also appear in text and as an image)
    VOCAB_TEXT, // Word appears underlined in the text (may also appear as an image)
    VOCAB_IMAGE // Word appears only as an image
} VocabularyType;

@interface Chapter : NSObject {
    NSString *title; //Title of this chapter.
    NSString* chapterTitlePage; //Any page associated with the chapter title. 
    NSString *chapterImagePath; //Any image path that may be associated with a cover page for this chapter.
    NSString* chapterId;
    NSInteger pageNum; //page number the chapter starts on. 
    NSMutableArray* content; //NOTE: This is being stored but not currently being used anywhere. It may be worthwhile to collapse the activities in the content array and contain all content in one place.
    NSMutableArray* activities; //List of activities corresponding to this chapter.
}

@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* chapterTitlePage;
@property (nonatomic, strong) NSString* chapterImagePath;
@property (nonatomic, strong) NSString* chapterId;
@property (nonatomic, strong) NSMutableArray* content;
@property (nonatomic, strong) NSMutableArray* activities;
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, strong) NSMutableDictionary *vocabulary;

-(void) addActivity:(Activity*)activity; //Add an activity to the chapter.

-(Activity*) getActivityOfType:(Mode) mode;

-(NSString*) getNextPageForMode:(Mode) mode :(NSString*)currentPage;  //Get the next page in this chapter.

- (void)addEmbraceScript:(ScriptAudio *)script forSentence:(NSString *)sentenceId;
- (void)addControlScript:(ScriptAudio *)script forSentence:(NSString *)sentenceId;

- (ScriptAudio *)embraceScriptFor:(NSString *)sentenceId;
- (ScriptAudio *)controlScriptFor:(NSString *)sentenceId;

- (NSMutableSet *)getVocabularyOfType:(VocabularyType)type; // Returns vocabulary for specified type

@end
