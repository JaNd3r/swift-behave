//
//  Scenario.h
//  https://github.com/JaNd3r/swift-behave
//
//  Created by Christian Klaproth on 01s.07.16.
//  Copyright (c) 2016 Christian Klaproth. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Scenario : NSObject

@property (nonatomic) NSString* scenarioName;
@property (nonatomic) NSArray* steps;

@end
