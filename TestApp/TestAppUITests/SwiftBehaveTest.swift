//
//  SwiftBehaveTests.swift
//  https://github.com/JaNd3r/swift-behave
//
//  Created by Christian Klaproth on 01.12.15.
//  Copyright (c) 2015 Christian Klaproth. All rights reserved.
//

import XCTest

protocol MappingProvider {
 
    func mappingFromPlist() -> Dictionary<String, String>
    
}

class SwiftBehaveTest: ScenarioTestCase, MappingProvider {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
        XCUIApplication().launch()
        // Wait for launch screen to disappear
        NSThread.sleepForTimeInterval(0.5)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    @objc override static func scenarios() -> AnyObject {
        let filename = self.storyfile()
        
        var testArray: Array<String> = []
        
        if let fullpath = NSBundle(forClass: SwiftBehaveTest.self).pathForResource(filename, ofType: "story") {
            do {
                let text = try String(contentsOfFile: fullpath, encoding: NSUTF8StringEncoding)
                testArray = text.componentsSeparatedByString("\n")
            } catch _ as NSError {
                print("error reading story file \(filename)")
                return NSArray()
            }
        }
        
        var currentName = ""
        var currentSteps = Array<String>()
        let returnArray = NSMutableArray()
        
        for testStep in testArray {
            
            if (testStep.characters.count == 0 || testStep.hasPrefix("Narrative:")) {
                // ignore empty lines and introducing narrative line
                continue
            }
            
            if (testStep.hasPrefix("Scenario: ")) {
                
                // are we currently building a scenario?
                if (currentName.characters.count > 0) {
                    // then finish the current scenario...
                    let scenario = Scenario()
                    scenario.scenarioName = currentName;
                    scenario.steps = currentSteps;
                    
                    print("Adding scenario '\(currentName)' with \(currentSteps.count) steps.")
                    
                    returnArray.addObject(scenario)
                    currentSteps.removeAll()
                }
                
                // ...and start a new scenario
                currentName = testStep.substringFromIndex(testStep.startIndex.advancedBy(10))
                print("Found start of test scenario '\(currentName)'")
                continue
            }
            
            currentSteps.append(testStep)
        }
        
        // add the last (or single) scenario, if one was found
        if (currentName.characters.count > 0) {
            // then finish the current scenario...
            let scenario = Scenario()
            scenario.scenarioName = currentName;
            scenario.steps = currentSteps;
            
            print("Adding scenario '\(currentName)' with \(currentSteps.count) steps.")
            
            returnArray.addObject(scenario)
        }
        
        print("Teststory '\(filename)' with \(returnArray.count) scenarios created.")
        
        return returnArray
    }
    
    func testScenario() {
        let mapping = self.mappingFromPlist()
        let app = XCUIApplication()
        
        print("Executing '\(scenarioName)' in \(self.dynamicType) with \(steps.count) steps.")
        
        for testStep in steps as! Array<String> {
            // finde func fuer testStep
            if (testStep.hasPrefix("Given ")) {
                let plainStep = testStep.substringFromIndex(testStep.startIndex.advancedBy(6))
                self.callSelectorFor(plainStep, inDictionary: mapping, withApp: app)
                continue
            }
            
            if (testStep.hasPrefix("When ")) {
                let plainStep = testStep.substringFromIndex(testStep.startIndex.advancedBy(5))
                self.callSelectorFor(plainStep, inDictionary: mapping, withApp: app)
                continue
            }
            
            if (testStep.hasPrefix("Then ")) {
                let plainStep = testStep.substringFromIndex(testStep.startIndex.advancedBy(5))
                self.callSelectorFor(plainStep, inDictionary: mapping, withApp: app)
                continue
            }
            
            if (testStep.hasPrefix("And ")) {
                let plainStep = testStep.substringFromIndex(testStep.startIndex.advancedBy(4))
                self.callSelectorFor(plainStep, inDictionary: mapping, withApp: app)
                continue
            }
        }
    }
    
    func callSelectorFor(step: String, inDictionary dict: Dictionary<String, String>, withApp app: XCUIApplication) -> Bool {
        
        for key in dict.keys {

            var parameterNames: Array<String> = []
            var parameterValues: Array<String> = []
            
            var match = true
            var index = 0
            
            let keyArray = key.componentsSeparatedByString(" ")
            let stepArray = step.componentsSeparatedByString(" ")
            
            for keyElem in keyArray {
                
                if (keyElem.hasPrefix("$")) {
                    parameterNames.append(keyElem.substringFromIndex(keyElem.startIndex.advancedBy(1)))
                    
                    var tempParameterString = stepArray[index]
                    index += 1
                    
                    // if value starts with '"' include all components until the closing '"'
                    if (tempParameterString.hasPrefix("\"")) {
                        tempParameterString = tempParameterString.substringFromIndex(tempParameterString.startIndex.advancedBy(1))
                        while (!tempParameterString.hasSuffix("\"")) {
                            tempParameterString = "\(tempParameterString) \(stepArray[index])"
                            index += 1
                        }
                        tempParameterString = tempParameterString.substringToIndex(tempParameterString.endIndex.advancedBy(-1))
                    }
                    
                    parameterValues.append(tempParameterString)
                    continue
                }
                
                if (keyElem == stepArray[index]) {
                    index += 1
                    continue
                }
                
                match = false
                break;
            }
            
            if (match) {
                
                // create and call corresponding selector
                // first parameter passed to the selector is the app (XCUIApplication) itself
                
                if (parameterNames.count == 0) {
                    if let selectorString = dict[key] {
                        self.performSelector(Selector.init("\(selectorString):"), withObject: app)
                        return true
                    }
                }
                
                // if there is a single parameter in the test sentence, a selector is performed
                // whos second parameter's name equals the behaviour-parameter's name
                
                if (parameterNames.count == 1) {
                    if let selectorString = dict[key] {
                        self.performSelector(Selector.init("\(selectorString):\(parameterNames[0]):"), withObject: app, withObject: parameterValues[0])
                        return true
                    }
                }
                
                // starting with two parameters a dictionary containg all parameters is created
                // and is passed as the second argument
                
                if (parameterNames.count > 1) {
                    if let selectorString = dict[key] {
                        var parameterDictionary = Dictionary<String, String>()
                        for (key, value) in zip(parameterNames, parameterValues) {
                            parameterDictionary[key] = value
                        }
                        self.performSelector(Selector.init("\(selectorString):parameters:"), withObject: app, withObject: parameterDictionary)
                    }
                }
                return false
            }
        }
        return false
    }
}
