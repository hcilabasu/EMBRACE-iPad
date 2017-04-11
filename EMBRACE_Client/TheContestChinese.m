//
//  TheContestChinese.m
//  EMBRACE
//
//  Created by Shang Wang on 2/28/17.
//  Copyright © 2017 Andreea Danielescu. All rights reserved.
//

#import "TheContestChinese.h"
#import "ManipulationViewController.h"
@implementation TheContestChinese
@synthesize speechState;
@synthesize  parentManipCtr;
- (id) init
{
    if (self = [super init])
    {
       
        speechState=0;
        [self configureOnlineTTS];
        [[BDSSpeechSynthesizer sharedInstance] setSynthesizerParam:[NSNumber numberWithFloat:10.0]
                                                            forKey: BDS_SYNTHESIZER_PARAM_ONLINE_REQUEST_TIMEOUT ];
        
         [[BDSSpeechSynthesizer sharedInstance] setSynthesizerDelegate: self];
    }
    return self;
}

-(void)playSentence: (int)index{
       NSError* speakerr;
    if(1==index){
        [[BDSSpeechSynthesizer sharedInstance] speakSentence: @"农夫马里奥召集了所有的动物" withError:&speakerr];
    }else if (2==index){
         [[BDSSpeechSynthesizer sharedInstance] speakSentence: @"他打开了牛的栅栏" withError:&speakerr];
    }else if (3==index){
        [[BDSSpeechSynthesizer sharedInstance] speakSentence: @"牛走向了围栏" withError:&speakerr];
    }else if (4==index){
        [[BDSSpeechSynthesizer sharedInstance] speakSentence: @"然后, 马里奥打开了山羊的栅栏,山羊走向了牛。" withError:&speakerr];
    }else if (5==index){
        [[BDSSpeechSynthesizer sharedInstance] speakSentence: @"小鸡从屋顶上飞了下来，坐在了牛的背上。" withError:&speakerr];
    }
}


-(void)playTranslation: (NSString*)englishTxt {
    speechState=1;
    NSError* speakerr;
    if([englishTxt isEqualToString:@"Manuel"]){
        [[BDSSpeechSynthesizer sharedInstance] speakSentence: @"马里奥" withError:&speakerr];
    }else if ([englishTxt isEqualToString:@"brushed"]){
        [[BDSSpeechSynthesizer sharedInstance] speakSentence: @"梳理" withError:&speakerr];
    }else if ([englishTxt isEqualToString:@"carried"]){
        [[BDSSpeechSynthesizer sharedInstance] speakSentence: @"搬运" withError:&speakerr];
    }
    else if ([englishTxt isEqualToString:@"bucket"]){
        [[BDSSpeechSynthesizer sharedInstance] speakSentence: @"篮子" withError:&speakerr];
    }
    else if ([englishTxt isEqualToString:@"shiny"]){
        [[BDSSpeechSynthesizer sharedInstance] speakSentence: @"闪亮" withError:&speakerr];
    }
}


-(void)configureOnlineTTS{
    
    NSString* offlineEngineSpeechData = [[NSBundle mainBundle] pathForResource:@"Chinese_Speech_Female" ofType:@"dat"];
    NSString* offlineEngineTextData = [[NSBundle mainBundle] pathForResource:@"Chinese_Text" ofType:@"dat"];
    NSString* offlineEngineEnglishSpeechData = [[NSBundle mainBundle] pathForResource:@"English_Speech_Female" ofType:@"dat"];
    NSString* offlineEngineEnglishTextData = [[NSBundle mainBundle] pathForResource:@"English_Text" ofType:@"dat"];
    
    
     NSString* licenseDat = [[NSBundle mainBundle] pathForResource:@"temp_license" ofType:nil];
    
    [[BDSSpeechSynthesizer sharedInstance] setApiKey:@"N0xhGEV647Coa1W5ywixKKZl" withSecretKey:@"09ff49a674941878f212f2531e2eb4fb"];
    
    
    
    BOOL b1=  [[NSFileManager defaultManager] fileExistsAtPath:offlineEngineTextData];
    BOOL b2=  [[NSFileManager defaultManager] fileExistsAtPath:offlineEngineSpeechData];
    
    ///无法实现离线语音请检查以下部分
    NSError* err = [[BDSSpeechSynthesizer sharedInstance] loadOfflineEngine:offlineEngineTextData speechDataPath:offlineEngineSpeechData licenseFilePath:nil withAppCode:@"9317413"];

    if( err!= nil) {}
    
    if(err){
        return;
    }
   // [self setCurrentOfflineSpeaker:OfflineSpeaker_Female];
    err = [[BDSSpeechSynthesizer sharedInstance] loadEnglishDataForOfflineEngine:offlineEngineEnglishTextData speechData:offlineEngineEnglishSpeechData];
    if(err){
        return;
    }
}


- (void)synthesizerSpeechEndSentence:(NSInteger)SynthesizeSentence{
    if(1==speechState){
        [parentManipCtr playEnglishSpeech];
    }
    
    NSLog(@"");
    
    speechState=0;
}



@end
