//
//  ScenarioTestCase.h
//  https://github.com/JaNd3r/swift-behave
//
//  Created by Christian Klaproth on 01.07.16.
//  Copyright (c) 2016 Christian Klaproth. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ScenarioTestCase : XCTestCase

+ (void)addScenarioWithName:(NSString* _Nonnull)scenarioName steps:(NSArray* _Nonnull)steps environment:(NSDictionary<NSString*,NSString*>* _Nonnull)environment testSuite:(XCTestSuite* _Nonnull)suite;

+ (NSArray* _Nonnull)scenarios;
+ (NSString* _Nonnull)storyfile;

@property (nonatomic) NSString* _Nonnull scenarioName;
@property (nonatomic) NSArray* _Nonnull steps;
@property (nonatomic) NSDictionary<NSString*,NSString*>* _Nonnull environment;

- (instancetype _Nonnull)initWithInvocation:(NSInvocation* _Nonnull)invocation name:(NSString* _Nonnull)scenarioName steps:(NSArray* _Nonnull)steps environment:(NSDictionary* _Nonnull)environment;

@end
