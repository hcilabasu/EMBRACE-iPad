//
//  InitializationHandler.h
//  EMBRACE
//
//  Created by Shang Wang on 4/9/18.
//  Copyright © 2018 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ManipulationViewController;
@interface InitializationHandler : NSObject
@property (nonatomic, strong) ManipulationViewController* parentManipulaitonCtr;
-(void)initlizeManipulaitonCtr;


@end
