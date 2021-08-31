//
//  ScenarioTestCase.m
//  https://github.com/JaNd3r/swift-behave
//
//  Created by Christian Klaproth on 01.07.16.
//  Copyright (c) 2016 Christian Klaproth. All rights reserved.
//

#import "ScenarioTestCase.h"
#import "Scenario.h"
#import <objc/runtime.h>

@implementation ScenarioTestCase

+ (id)defaultTestSuite
{
    NSString* selfClassName = NSStringFromClass(self);
    if ([selfClassName isEqualToString:@"ScenarioTestCase"] || [selfClassName isEqualToString:@"SwiftBehaveTest"]) {
        // don't execute swift-behave framework test classes
        return nil;
    }
    
    XCTestSuite* suite = [[XCTestSuite alloc] initWithName:NSStringFromClass(self)];
    for (Scenario* scenario in [self scenarios]) {
        [self addScenarioWithName:scenario.scenarioName steps:scenario.steps environment:scenario.environment testSuite:suite];
    }
    return suite;
}

+ (NSArray*)scenarios
{
    return @[];
}

+ (void)addScenarioWithName:(NSString*)scenarioName steps:(NSArray*)steps environment:(NSDictionary<NSString*,NSString*>* _Nonnull)environment testSuite:(XCTestSuite*)suite
{
    for (NSInvocation* invocation in [self testInvocations]) {
        
        // here goes the tricky part: replace the selector within the invocation
        // with a newly created instance method with a name derived from the
        // scenario name.
        SEL selector = [self addInstanceMethodForScenario:scenarioName];
        invocation.selector = selector;
        
        XCTestCase* test = [[self alloc] initWithInvocation:invocation name:scenarioName steps:steps environment:environment];
        [suite addTest:test];
    }
}

+ (NSString*)storyfile
{
    // must be overriden in concrete swift-behave sub classes
    return @"OVERRIDE";
}

- (instancetype)initWithInvocation:(NSInvocation*)invocation name:(NSString*)scenarioName steps:(NSArray*)steps environment:(NSDictionary*)environment
{
    self = [super initWithInvocation:invocation];
    if (self) {
        _scenarioName = scenarioName;
        _steps = steps;
        _environment = environment;
    }
    
    return self;
}

+ (SEL)addInstanceMethodForScenario:(NSString*)scenarioName
{
    IMP implementation = imp_implementationWithBlock(^(ScenarioTestCase* self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:NSSelectorFromString(@"testScenario")];
#pragma clang diagnostic pop
    });
    
    NSArray* selectorComponents = [scenarioName componentsSeparatedByString:@" "];
    NSString* selectorName = [selectorComponents componentsJoinedByString:@"_"];
    
    SEL selector = NSSelectorFromString(selectorName);
    const char* types = [@"v@:" UTF8String];
    class_addMethod(self, selector, implementation, types);
    return selector;
}

@end
