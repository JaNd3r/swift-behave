//
//  ScenarioTestCase.h
//  https://github.com/JaNd3r/swift-behave
//
//  Created by Christian Klaproth on 01.07.16.
//  Copyright (c) 2016 Christian Klaproth. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ScenarioTestCase : XCTestCase

+ (void)addScenarioWithName:(NSString*)scenarioName steps:(NSArray*)steps testSuite:(XCTestSuite*)suite;

+ (id)scenarios;
+ (NSString*)storyfile;

@property (nonatomic) NSString* scenarioName;
@property (nonatomic) NSArray* steps;

- (instancetype)initWithInvocation:(NSInvocation*)invocation name:(NSString*)scenarioName steps:(NSArray*)steps;

@end
