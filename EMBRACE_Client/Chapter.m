//
//  Chapter.m
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 6/5/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Chapter.h"
#import "Translation.h"

@interface Chapter()

@property (nonatomic, strong) NSMutableDictionary *embraceAudio;
@property (nonatomic, strong) NSMutableDictionary *controlAudio;

@end

@implementation Chapter

@synthesize title;
@synthesize chapterTitlePage;
@synthesize chapterImagePath;
@synthesize chapterId;
@synthesize content;
@synthesize activities;
@synthesize pageNum;

- (id) init {
    if (self = [super init]) {
        activities = [[NSMutableArray alloc] init];
        content = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void) addActivity:(Activity*)activity {
    [activities addObject:activity];
}

-(Activity*) getActivityOfType:(Mode) mode {
    for(Activity* activity in activities) {
        if((mode == PM_MODE) && ([activity isKindOfClass:[PhysicalManipulationActivity class]]))
            return activity;
        else if((mode == ITSPM_MODE) && ([activity isKindOfClass:[ITSPhysicalManipulationActivity class]]))
            return activity;
        else if((mode == IM_MODE) && ([activity isKindOfClass:[ImagineManipulationActivity class]]))
            return activity;
        else if((mode == ITSIM_MODE) && ([activity isKindOfClass:[ITSImagineManipulationActivity class]]))
            return activity;
    }
    return nil;
}

-(NSString*) getNextPageForMode:(Mode) mode :(NSString*)currentPage {
    for(Activity* activity in activities) {
        if((mode == PM_MODE) && ([activity isKindOfClass:[PhysicalManipulationActivity class]])) {
            return [self getNextPageInActivity:activity :currentPage];
        }
        if((mode == ITSPM_MODE) && ([activity isKindOfClass:[ITSPhysicalManipulationActivity class]])) {
            return [self getNextPageInActivity:activity :currentPage];
        }
        else if(mode == IM_MODE && ([activity isKindOfClass:[ImagineManipulationActivity class]])) {
            return [self getNextPageInActivity:activity :currentPage];
        }
        else if(mode == ITSIM_MODE && ([activity isKindOfClass:[ITSImagineManipulationActivity class]])) {
            return [self getNextPageInActivity:activity :currentPage];
        }
    }
    
    return nil;
}

-(NSString*) getPreviousPageForMode:(Mode) mode :(NSString*)currentPage {
    for(Activity* activity in activities) {
        if((mode == PM_MODE) && ([activity isKindOfClass:[PhysicalManipulationActivity class]])) {
            return [self getPreviousPageInActivity:activity :currentPage];
        }
        if((mode == ITSPM_MODE) && ([activity isKindOfClass:[ITSPhysicalManipulationActivity class]])) {
            return [self getPreviousPageInActivity:activity :currentPage];
        }
        else if(mode == IM_MODE && ([activity isKindOfClass:[ImagineManipulationActivity class]])) {
            return [self getPreviousPageInActivity:activity :currentPage];
        }
        else if(mode == ITSIM_MODE && ([activity isKindOfClass:[ITSImagineManipulationActivity class]])) {
            return [self getPreviousPageInActivity:activity :currentPage];
        }
    }
    
    return nil;
}

-(NSString*) getNextPageInActivity:(Activity* )activity :(NSString* )currentPage {
    NSMutableArray* pages = [activity pages];
    
    //If we're loading the first page.
    if(currentPage == nil) {
        //NSLog(@"current Page is nil");
        return [[pages objectAtIndex:0] pagePath];
    }
    
    //NSLog(@"current page is not nil...looking for next page");
    
    for(int i = 0; i < [pages count]; i ++) {
        Page* page = [pages objectAtIndex:i];
        
        //if we've found the current page, we can return the next page, if there is a next page.
        if([[page pagePath] isEqualToString:currentPage]) {
            if(i < [pages count] - 1)
                return [[pages objectAtIndex:i + 1] pagePath];
        }
    }
    
    return nil;
}

-(NSString*) getPreviousPageInActivity:(Activity* )activity :(NSString* )currentPage {
    NSMutableArray* pages = [activity pages];
    
    //If we're loading the first page.
    if(currentPage == nil) {
        //NSLog(@"current Page is nil");
        return [[pages objectAtIndex:0] pagePath];
    }
    
    //NSLog(@"current page is not nil...looking for next page");
    
    for(int i = 0; i < [pages count]; i ++) {
        Page* page = [pages objectAtIndex:i];
        
        //if we've found the current page, we can return the next page, if there is a next page.
        if([[page pagePath] isEqualToString:currentPage]) {
            if(i > 0)
                return [[pages objectAtIndex:i - 1] pagePath];
        }
    }
    
    return nil;
}


- (void)addEmbraceScript:(ScriptAudio *)script forSentence:(NSString *)sentenceId {
    if (self.embraceAudio == nil) {
        self.embraceAudio = [NSMutableDictionary dictionary];
    }
    [self.embraceAudio setObject:script forKey:sentenceId];
    
}
- (void)addControlScript:(ScriptAudio *)script forSentence:(NSString *)sentenceId {
    if (self.controlAudio == nil) {
        self.controlAudio = [NSMutableDictionary dictionary];
    }
    [self.controlAudio setObject:script forKey:sentenceId];
}

- (ScriptAudio *)embraceScriptFor:(NSString *)sentenceId {
    if (self.embraceAudio) {
        return [self.embraceAudio objectForKey:sentenceId];
    }
    return nil;
}

- (ScriptAudio *)controlScriptFor:(NSString *)sentenceId {
    if (self.controlAudio) {
        return [self.controlAudio objectForKey:sentenceId];
    }
    return nil;
}

- (NSMutableSet *)getNewVocabulary {
    NSMutableSet *newVocabulary = [[NSMutableSet alloc] init];
    
    for (NSString *vocabulary in [self vocabulary]) {
        if ([[[self vocabulary] objectForKey:vocabulary] isEqual: @(TRUE)]) {
            [newVocabulary addObject:vocabulary];
        }
    }
    
    return newVocabulary;
}

- (NSMutableSet *)getOldVocabulary {
    NSMutableSet *oldVocabulary = [[NSMutableSet alloc] init];
    
    for (NSString *vocabulary in [self vocabulary]) {
        if ([[[self vocabulary] objectForKey:vocabulary] isEqual: @(FALSE)]) {
            [oldVocabulary addObject:vocabulary];
        }
    }
    
    return oldVocabulary;
}

- (NSMutableSet *)getVocabularyFromSolutions {
    NSMutableSet *solutionVocabulary = [[NSMutableSet alloc] init];
    NSMutableDictionary *PMSolutions = [(PhysicalManipulationActivity *)[self getActivityOfType:PM_MODE] PMSolutions];
    
    for (NSString *activityId in PMSolutions) {
        PhysicalManipulationSolution *PMSolution = [[PMSolutions objectForKey:activityId] objectAtIndex:0];
        
        for (ActionStep *actionStep in [PMSolution solutionSteps]) {
            NSString *object1Id = [actionStep object1Id];
            NSString *object2Id = [actionStep object2Id];
            
            if (object1Id != nil) {
                // Get all possible keys (vocabulary) that may correspond to this object
                NSArray *possibleKeys = [[[Translation translationImages] keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop)
                    {
                        if ([obj isKindOfClass:[NSArray class]]) {
                            return [obj containsObject:object1Id];
                        }
                        else {
                            return [obj isEqual:object1Id];
                        }
                    }] allObjects];
                
                if ([possibleKeys count] > 0) {
                    // For now, assume the correct corresponding vocabulary is the last element
                    // It seems like the more specific vocabulary (e.g., "Paco" instead of "pets") is usually last.
                    [solutionVocabulary addObject:[possibleKeys lastObject]];
                }
                else {
                    // Discard vocabulary with numbers, uppercase letters, or underscores
                    if ([object1Id rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound && [object1Id rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location == NSNotFound && ![object1Id containsString:@"_"]) {
                        [solutionVocabulary addObject:object1Id];
                    }
                }
            }
            
            if (object2Id != nil) {
                // Get all possible keys (vocabulary) that may correspond to this object
                NSArray *possibleKeys = [[[Translation translationImages] keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop)
                    {
                        if ([obj isKindOfClass:[NSArray class]]) {
                            return [obj containsObject:object2Id];
                        }
                        else {
                            return [obj isEqual:object2Id];
                        }
                    }] allObjects];
                
                if ([possibleKeys count] > 0) {
                    // For now, assume the correct corresponding vocabulary is the last element
                    // It seems like the more specific vocabulary (e.g., "Paco" instead of "pets") is usually last.
                    [solutionVocabulary addObject:[possibleKeys lastObject]];
                }
                else {
                    // Discard vocabulary with numbers, uppercase letters, or underscores
                    if ([object2Id rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound && [object2Id rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location == NSNotFound && ![object2Id containsString:@"_"]) {
                        [solutionVocabulary addObject:object2Id];
                    }
                }
            }
        }
    }
    
    // NOTE: Currently hardcoded to remove invalid solution vocabulary that could not be filtered out
    if ([title isEqualToString:@"Words of Wisdom"]) {
        if ([solutionVocabulary containsObject:@"babybrother"]) {
            [solutionVocabulary removeObject:@"babybrother"];
        }
    }
    if ([title isEqualToString:@"A Friend in Need"]) {
        NSArray *myArray = @[@"sofia"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    
    
    //TODO: REMOVE HARD CODED SOLUTION FOR ADDING VOCAB
    //DISASTER VOCAB
    if ([title isEqualToString:@"The Moving Earth"]) {
        NSArray *myArray = @[@"awhile", @"California", @"cloud", @"columns", @"disasters", @"disaster", @"drifted", @"earth", @"earthquake", @"earthquakes", @"enough", @"fault line", @"forest", @"Hawai'i", @"Hawaiian", @"Himalaya", @"hotspot", @"India", @"islands", @"island", @"kaua'i", @"lava", @"mantle", @"million", @"mountains", @"nature", @"Oahu", @"ocean", @"oceans", @"Pacific", @"plate tectonics", @"pressure", @"rapidly", @"rise", @"serious", @"spew", @"spews", @"spin", @"spining", @"supercell", @"swirl", @"swirls", @"swirling", @"sometimes", @"tornado", @"tornados", @"tsunami", @"tsunamis", @"violent", @"volcano", @"volcanoes", @"winds"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Earthquakes"]) {
        NSArray *myArray = @[@"awhile", @"California", @"cloud", @"columns", @"disasters", @"disaster", @"drifted", @"earth", @"earthquake", @"earthquakes", @"enough", @"fault line", @"forest", @"Hawai'i", @"Hawaiian", @"Himalaya", @"hotspot", @"India", @"islands", @"island", @"kaua'i", @"lava", @"mantle", @"million", @"mountains", @"nature", @"Oahu", @"ocean", @"oceans", @"Pacific", @"plate tectonics", @"pressure", @"rapidly", @"rise", @"serious", @"spew", @"spews", @"spin", @"spining", @"supercell", @"swirl", @"swirls", @"swirling", @"sometimes", @"tornado", @"tornados", @"tsunami", @"tsunamis", @"violent", @"volcano", @"volcanoes", @"winds"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Tsunamis"]) {
        NSArray *myArray = @[@"awhile", @"California", @"cloud", @"columns", @"disasters", @"disaster", @"drifted", @"earth", @"earthquake", @"earthquakes", @"enough", @"fault line", @"forest", @"Hawai'i", @"Hawaiian", @"Himalaya", @"hotspot", @"India", @"islands", @"island", @"kaua'i", @"lava", @"mantle", @"million", @"mountains", @"nature", @"Oahu", @"ocean", @"oceans", @"Pacific", @"plate tectonics", @"pressure", @"rapidly", @"rise", @"serious", @"spew", @"spews", @"spin", @"spining", @"supercell", @"swirl", @"swirls", @"swirling", @"sometimes", @"tornado", @"tornados", @"tsunami", @"tsunamis", @"violent", @"volcano", @"volcanoes", @"winds"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Volcanoes and the Making of Hawaii"]) {
        NSArray *myArray = @[@"awhile", @"California", @"cloud", @"columns", @"disasters", @"disaster", @"drifted", @"earth", @"earthquake", @"earthquakes", @"enough", @"fault line", @"forest", @"Hawai'i", @"Hawaiian", @"Himalaya", @"hotspot", @"India", @"islands", @"island", @"kaua'i", @"lava", @"mantle", @"million", @"mountains", @"nature", @"Oahu", @"ocean", @"oceans", @"Pacific", @"plate tectonics", @"pressure", @"rapidly", @"rise", @"serious", @"spew", @"spews", @"spin", @"spining", @"supercell", @"swirl", @"swirls", @"swirling", @"sometimes", @"tornado", @"tornados", @"tsunami", @"tsunamis", @"violent", @"volcano", @"volcanoes", @"winds"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Tornados"]) {
        NSArray *myArray = @[@"awhile", @"California", @"cloud", @"columns", @"disasters", @"disaster", @"drifted", @"earth", @"earthquake", @"earthquakes", @"enough", @"fault line", @"forest", @"Hawai'i", @"Hawaiian", @"Himalaya", @"hotspot", @"India", @"islands", @"island", @"kaua'i", @"lava", @"mantle", @"million", @"mountains", @"nature", @"Oahu", @"ocean", @"oceans", @"Pacific", @"plate tectonics", @"pressure", @"rapidly", @"rise", @"serious", @"spew", @"spews", @"spin", @"spining", @"supercell", @"swirl", @"swirls", @"swirling", @"sometimes", @"tornado", @"tornados", @"tsunami", @"tsunamis", @"violent", @"volcano", @"volcanoes", @"winds"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    
    //CELEBRATION VOCAB
    if ([title isEqualToString:@"Key Ingredients"]) {
        NSArray *myArray = @[@"celebration", @"champurrado", @"enthusiastically", @"evening", @"grind", @"ingredients", @"mole", @"supplies", @"tote", @"bridle", @"calf", @"cattle", @"corral", @"dairy", @"dozen", @"guide", @"guided", @"herd", @"post", @"produce", @"saddle", @"scale", @"straps", @"successful", @"tomatillos", @"vase", @"mancha", @"sofia", @"sofía"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Mancha the Horse"]) {
        NSArray *myArray = @[@"celebration", @"champurrado", @"enthusiastically", @"evening", @"grind", @"ingredients", @"mole", @"supplies", @"tote", @"bridle", @"calf", @"cattle", @"corral", @"dairy", @"dozen", @"guide", @"guided", @"herd", @"post", @"produce", @"saddle", @"scale", @"straps", @"successful", @"tomatillos", @"vase", @"mancha", @"sofia", @"sofía"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"A Friend in Need"]) {
        NSArray *myArray = @[@"celebration", @"champurrado", @"enthusiastically", @"evening", @"grind", @"ingredients", @"mole", @"supplies", @"tote", @"bridle", @"calf", @"cattle", @"corral", @"dairy", @"dozen", @"guide", @"guided", @"herd", @"post", @"produce", @"saddle", @"scale", @"straps", @"successful", @"tomatillos", @"vase", @"mancha", @"sofia", @"sofía"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Shopping at the Market"]) {
        NSArray *myArray = @[@"celebration", @"champurrado", @"enthusiastically", @"evening", @"grind", @"ingredients", @"mole", @"supplies", @"tote", @"bridle", @"calf", @"cattle", @"corral", @"dairy", @"dozen", @"guide", @"guided", @"herd", @"post", @"produce", @"saddle", @"scale", @"straps", @"successful", @"tomatillos", @"vase", @"mancha", @"sofia", @"sofía"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"A Gift for the Bride"]) {
        NSArray *myArray = @[@"celebration", @"champurrado", @"enthusiastically", @"evening", @"grind", @"ingredients", @"mole", @"supplies", @"tote", @"bridle", @"calf", @"cattle", @"corral", @"dairy", @"dozen", @"guide", @"guided", @"herd", @"post", @"produce", @"saddle", @"scale", @"straps", @"successful", @"tomatillos", @"vase", @"mancha", @"sofia", @"sofía"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Homecoming"]) {
        NSArray *myArray = @[@"celebration", @"champurrado", @"enthusiastically", @"evening", @"grind", @"ingredients", @"mole", @"supplies", @"tote", @"bridle", @"calf", @"cattle", @"corral", @"dairy", @"dozen", @"guide", @"guided", @"herd", @"post", @"produce", @"saddle", @"scale", @"straps", @"successful", @"tomatillos", @"vase", @"mancha", @"sofia", @"sofía"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    
    return solutionVocabulary;
}

@end
