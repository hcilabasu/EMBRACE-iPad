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
@synthesize contentString;
- (id) init {
    if (self = [super init]) {
        activities = [[NSMutableArray alloc] init];
        content = [[NSMutableArray alloc] init];
        contentString = [[NSMutableArray alloc] init];
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
        NSArray *myArray = @[@"California", @"disasters", @"disaster", @"drifted", @"earth", @"Himalaya", @"India", @"mantle", @"million", @"mountains", @"ocean", @"oceans", @"spin", @"spinning",   @"sometimes"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Earthquakes"]) {
        NSArray *myArray = @[@"California", @"earthquake", @"earthquakes", @"fault line", @"mantle", @"plate tectonics", @"pressure", @"sometimes"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Tsunamis"]) {
        NSArray *myArray = @[@"earthquake", @"earthquakes", @"India", @"ocean", @"oceans",  @"sometimes", @"tsunami", @"tsunamis"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Volcanoes and the Making of Hawaii"]) {
        NSArray *myArray = @[@"earth", @"enough", @"Hawai'i", @"Hawaiian", @"hotspot", @"islands", @"island", @"kaua'i", @"lava", @"mantle", @"million", @"Oahu", @"ocean", @"oceans", @"Pacific", @"spew", @"spews", @"sometimes", @"volcano", @"volcanoes"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"Tornados"]) {
        NSArray *myArray = @[@"awhile", @"cloud", @"columns", @"rapidly", @"rise", @"serious",  @"spin", @"spinning", @"supercell", @"swirl", @"swirls", @"swirling", @"tornado", @"tornados"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    
    //CELEBRATION VOCAB
    
    NSArray *fullArray = @[@"celebration", @"champurrado", @"enthusiastically", @"evening", @"grind", @"ingredients", @"mole", @"supplies", @"tote", @"bridle", @"calf", @"cattle", @"corral", @"dairy", @"dozen", @"guide", @"guided", @"herd", @"post", @"produce", @"saddle", @"scale", @"straps", @"successful", @"tomatillos", @"vase", @"mancha", @"sofia"];
    
    
    NSString *KIString=@"It was an early Saturday morning in May, and the house was buzzing with action. Everybody in the Romero family was preparing for the great celebration to take place that evening. Sofia’s sister, Olivia, was getting married! Sofia was in the kitchen helping her mom with the main course, which was mole. Sofia grabbed the bowl with red chilis and gave it to her mother to grind them. Honey, can you go stir the champurrado, please?” her mother asked. Sofia walked over to the stove and stirred the chocolaty drink so that it would not stick to the bottom of the pot. “Oh dear, Sofia!” her mother said. “We are missing some key ingredients. Sofia ran to get a notepad and pencil, and brought them to her mother. I will go fetch the ingredients from the market! she said enthusiastically. Sofia’s mom put a list of ingredients into a tote bag. She handed Sofia the tote to carry the supplies. You can buy whatever you want with the change,” she said to Sofia while handing her forty pesos. Thanks! Sofia replied as she ran out the door.";
    
    NSString* MTHString=@"Sofia walked to the corral to get her pinto horse for the trip to the market. Her horse’s name was Mancha, and he was a gift from her grandpa. Sofia loved Mancha and also loved riding him places. She walked over to the saddle and bridle and picked them up. She put the saddle on the horse and tied down the straps firmly like her grandpa had taught her. She also put the bridle on Mancha’s head. Before getting on, Sofia took the grocery list from her tote bag and read it just in case she lost it. She needed to buy tomatillos, milk, spinach, garlic, and mangoes. Sofia grabbed her tote bag, hopped on her horse, and rode out of the corral on her way to the market.";
    
    NSString* AFINString=@"Sofia rode down the dirt road toward the market. But she was soon stopped - there was a herd of cattle blocking her path. A young boy on a horse was trying to move the animals.  It was her friend Emilio. Sofia! Hi! Can you help me get my cattle into the corral? he exclaimed. Sure, Emilio! she replied. Sofia helped her friend by riding her horse back and forth behind the herd. The black and white cow wandered away from the herd. Sofia rode behind the cow to guide it back to the herd. The cows entered the corral starting with the black and white one. Almost all the cows were in the corral when a black calf ran in the opposite direction. Sofia acted quickly and rode her horse around the calf. The calf ran back to the herd and into the corral. Thank you, Sofia! Emilio said with a smile on his face. “Without your help, I would still be chasing cows. He then got off his horse and closed the corral gate behind his cattle.";
    
    NSString* SATMString=@"After helping her friend with his cattle, Sofia rode to the market. When Sofia arrived, she hopped off her horse and tied him to a post at the front of the market. Mancha leaned over and ate some grass while he waited for his owner. Sofia took her tote bag to the produce section and put lots of tomatillos into it. She put the bag on the scale and saw that it weighed one kilo. She also put a bunch of spinach in the tote. Next, she grabbed a kilo of the ripest mangoes and then a string of garlic. Finally, Sofia moved on to the dairy section and grabbed a carton of fresh milk. Sofia walked over to Mrs. Peña and paid for her groceries; the total was 30 pesos. She then carried her tote out to Mancha and put it into the blue saddlebag. Now she was ready to go home.";
    
    NSString* ATGFBString=@"Sofia got on her horse and rode back down the dirt road toward her house. She was happy that her outing was so successful, but had a feeling that she was forgetting something. And then it hit her that she had wanted to use the rest of the money to buy a wedding present for her older sister, Olivia. She turned around and rode as fast as she could back to the market. She tied up Mancha to the post and ran into the store. Sofia walked over to the roses and picked out a dozen pink roses and a dozen white roses. The pink roses showed Sofia’s love for Olivia, and the white roses showed the love between the bride and groom. She took them to the front to pay. Your sister is going to love these, Sofia!” said Mrs. Peña. Sofia took the flowers and put them into the brown saddlebag. Sofia rode back home, this time knowing that she had bought everything she needed.";
    
    NSString* HomecomingString=@"Sofia rode the rest of the way home and brought her horse into the corral. She removed the saddle and placed it back on the hook. She also removed the bridle and hung it on the other hook. Then she took the groceries and roses out of the saddlebags. Sofia walked in the door and greeted her mom cheerfully. Sofia emptied the tote onto the counter and said, “Here’s everything you asked for, Mom.  I even had enough money to buy Olivia these roses!” Sofia’s mom walked over to the counter and examined the groceries. She said, “You did a great job picking the freshest produce, Sofia! Now I can finish dinner, and we can have ourselves a party.” Sofia decided to do one last thing before joining the party.  She filled a tall, clear vase with water from the kitchen sink. (M) She placed the roses in the vase so that Olivia could enjoy them longer. (M)Sofia happily ran from the kitchen to join what was to be a celebration to remember!";
    
    
    if ([title isEqualToString:@"Key Ingredients"]) {
        NSMutableArray* mutAry= [[NSMutableArray alloc]init];
        for (NSString *vocabString in fullArray) {
            if( [KIString rangeOfString:vocabString].location != NSNotFound){
                [mutAry addObject:vocabString];
            }
        }
        NSArray *myArray = [mutAry copy];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    
    if ([title isEqualToString:@"Mancha the Horse"]) {
        NSMutableArray* mutAry= [[NSMutableArray alloc]init];
        for (NSString *vocabString in fullArray) {
            if( [MTHString rangeOfString:vocabString].location != NSNotFound){
                [mutAry addObject:vocabString];
            }
        }
        NSArray *myArray = [mutAry copy];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    if ([title isEqualToString:@"A Friend in Need"]) {
        NSMutableArray* mutAry= [[NSMutableArray alloc]init];
        for (NSString *vocabString in fullArray) {
            if( [AFINString rangeOfString:vocabString].location != NSNotFound){
                [mutAry addObject:vocabString];
            }
        }
        NSArray *myArray = [mutAry copy];
        [solutionVocabulary addObjectsFromArray:myArray];

    }
    if ([title isEqualToString:@"Shopping at the Market"]) {
        NSMutableArray* mutAry= [[NSMutableArray alloc]init];
        for (NSString *vocabString in fullArray) {
            if( [SATMString rangeOfString:vocabString].location != NSNotFound){
                [mutAry addObject:vocabString];
            }
        }
        NSArray *myArray = [mutAry copy];
        [solutionVocabulary addObjectsFromArray:myArray];

    }
    if ([title isEqualToString:@"A Gift for the Bride"]) {
        NSMutableArray* mutAry= [[NSMutableArray alloc]init];
        for (NSString *vocabString in fullArray) {
            if( [ATGFBString rangeOfString:vocabString].location != NSNotFound){
                [mutAry addObject:vocabString];
            }
        }
        NSArray *myArray = [mutAry copy];
        [solutionVocabulary addObjectsFromArray:myArray];

    }
    if ([title isEqualToString:@"Homecoming"]) {
        NSMutableArray* mutAry= [[NSMutableArray alloc]init];
        for (NSString *vocabString in fullArray) {
            if( [HomecomingString rangeOfString:vocabString].location != NSNotFound){
                [mutAry addObject:vocabString];
            }
        }
        NSArray *myArray = [mutAry copy];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    
    //NATIVE VOCAB
    if ([title isEqualToString:@"Introduction to Native American Homes"]) {
        NSArray *myArray = @[@"community", @"protect"];
        [solutionVocabulary addObjectsFromArray:myArray];
    }
    
    return solutionVocabulary;
}

@end
