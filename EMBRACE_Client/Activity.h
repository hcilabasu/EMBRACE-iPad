//
//  Activity.h
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 6/5/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Page.h"
#import "Solution.h"

//The mode enum will provide the information for what mode we're in.
typedef enum modeTypes {
    PM_MODE,
    IM_MODE
} Mode;

typedef enum modePhase {
    ACTION,
    INTRODUCTION,
    VOCAB
} Phase;

@interface Activity : NSObject {
    NSString* activityId;
    NSString* activityTitle;
    NSInteger pageNum; // page number the activity starts on.
    NSMutableArray* pages; //list of pages associated with this activity.
    //Note: Wonder if it's just worth having a mode associated with the activity....instead of subclassing.
    Solution* solution;
}

@property (nonatomic, strong) NSString* activityId;
@property (nonatomic, strong) NSString* activityTitle;
@property (nonatomic, strong) NSMutableArray* pages;
@property (nonatomic, assign) NSInteger pageNum;

-(void) addPage:(Page*) page;

@end
