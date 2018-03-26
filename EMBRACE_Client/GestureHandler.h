//
//  GestureHandler.h
//  EMBRACE
//
//  Created by Shang Wang on 3/19/18.
//  Copyright © 2018 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerCommunicationController.h"
@class ManipulationViewController;
@interface GestureHandler : NSObject
@property (nonatomic, strong) ManipulationViewController* parentManipulaitonCtr;

@end
