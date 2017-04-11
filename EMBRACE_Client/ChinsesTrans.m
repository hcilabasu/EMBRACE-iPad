//
//  ChinsesTrans.m
//  EMBRACE
//
//  Created by Shang Wang on 3/14/17.
//  Copyright © 2017 Andreea Danielescu. All rights reserved.
//

#import "ChinsesTrans.h"

@implementation ChinsesTrans







-(NSString*)ChinesetoEnglish: (NSString*) str{
    NSString* engStr=@"Judge";
    if([str isEqualToString:@"围栏"]){
        engStr=@"Contest";
    }else if([str isEqualToString:@"走"]){
        engStr=@"Chicken";
    }else if([str isEqualToString:@"山羊"]){
        engStr=@"Corral";
    }else if([str isEqualToString:@"从"]){
        engStr=@"Farm";
    }else if([str isEqualToString:@"屋顶上"]){
        engStr=@"Flew";
    }else if([str isEqualToString:@""]){
        engStr=@"Walked";
    }
    return engStr;
}



-(NSString*)EnglishtoChinese: (NSString*) str{
    NSString* chStr=@"评委";
    if([str isEqualToString:@"围栏"]){
        chStr=@"Contest";
    }else if([str isEqualToString:@"走"]){
        chStr=@"Chicken";
    }else if([str isEqualToString:@"山羊"]){
        chStr=@"Corral";
    }else if([str isEqualToString:@"从"]){
        chStr=@"Farm";
    }else if([str isEqualToString:@"屋顶上"]){
        chStr=@"Flew";
    }else if([str isEqualToString:@""]){
        chStr=@"Walked";
    }
    return chStr;
}



@end
