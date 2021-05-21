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
        let app = XCUIApplication()
        app.launchArguments.append("SwiftBehaveTest")
        app.launch()
        // Wait for launch screen to disappear
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    override static func scenarios() -> [Any] {
        let filename = self.storyfile()
        
        var testArray: Array<String> = []
        
        if let fullpath = Bundle(for: SwiftBehaveTest.self).path(forResource: filename, ofType: "story") {
            do {
                let text = try String(contentsOfFile: fullpath, encoding: .utf8)
                testArray = text.components(separatedBy: "\n")
            } catch _ as NSError {
                print("error reading story file \(filename)")
                return Array.init()
            }
        }
        
        var currentName = ""
        var currentSteps = Array<String>()
        var returnArray = [Any]()
        
        for testStep in testArray {
            
            if (testStep.count == 0 || testStep.hasPrefix("Narrative:")) {
                // ignore empty lines and introducing narrative line
                continue
            }
            
            if (testStep.hasPrefix("Scenario: ")) {
                
                // are we currently building a scenario?
                if (currentName.count > 0) {
                    // then finish the current scenario...
                    let scenario = Scenario()
                    scenario.scenarioName = currentName
                    scenario.steps = currentSteps
                    
                    print("Adding scenario '\(currentName)' with \(currentSteps.count) steps.")
                    
                    returnArray.append(scenario)
                    currentSteps.removeAll()
                }
                
                // ...and start a new scenario
                currentName = String(testStep.suffix(from: testStep.index(testStep.startIndex, offsetBy: 10)))
                print("Found start of test scenario '\(currentName)'")
                continue
            }
            
            currentSteps.append(testStep)
        }
        
        // add the last (or single) scenario, if one was found
        if (currentName.count > 0) {
            // then finish the current scenario...
            let scenario = Scenario()
            scenario.scenarioName = currentName
            scenario.steps = currentSteps
            
            print("Adding scenario '\(currentName)' with \(currentSteps.count) steps.")
            
            returnArray.append(scenario)
        }
        
        print("Teststory '\(filename)' with \(returnArray.count) scenarios created.")
        
        return returnArray
    }
    
    func testScenario() {
        let mapping = self.mappingFromPlist()
        let app = XCUIApplication()
        
        print("Executing '\(scenarioName)' in \(type(of: self)) with \(steps.count) steps.")
        
        for testStep in steps as! Array<String> {
            var success = false
            
            // find func for testStep
            if (testStep.hasPrefix("Given ")) {
                let plainStep = String(testStep.suffix(from: testStep.index(testStep.startIndex, offsetBy: 6)))
                success = self.callSelector(for: plainStep, inDictionary: mapping, withApp: app)
            } else if (testStep.hasPrefix("When ")) {
                let plainStep = String(testStep.suffix(from: testStep.index(testStep.startIndex, offsetBy: 5)))
                success = self.callSelector(for: plainStep, inDictionary: mapping, withApp: app)
            } else if (testStep.hasPrefix("Then ")) {
                let plainStep = String(testStep.suffix(from: testStep.index(testStep.startIndex, offsetBy: 5)))
                success = self.callSelector(for: plainStep, inDictionary: mapping, withApp: app)
            } else if (testStep.hasPrefix("And ")) {
                let plainStep = String(testStep.suffix(from: testStep.index(testStep.startIndex, offsetBy: 4)))
                success = self.callSelector(for: plainStep, inDictionary: mapping, withApp: app)
            }
            
            if (!success) {
                XCTFail("STEP FAILED: \(testStep)")
            }
        }
    }
    
    func callSelector(for stepText: String, inDictionary dict: Dictionary<String, String>, withApp app: XCUIApplication) -> Bool {
        
        var step = stepText
        var repetitions = 1
        
        if step.hasSuffix(" times") {
            let regex = try? NSRegularExpression(pattern: "\\d{1,2} times$", options: [])
            let stepAsNsString = step as NSString
            let results = regex?.matches(in: step, options: [], range: NSMakeRange(0, step.count))
            if let timesMatch = results?.first {
                let output = stepAsNsString.substring(with: timesMatch.range)
                step = String(describing: step.prefix(step.count - output.count))
                repetitions = Int(output.components(separatedBy: " ").first!)!
            }
        }
        
        for key in dict.keys {

            var parameterNames: Array<String> = []
            var parameterValues: Array<String> = []
            
            var match = true
            var index = 0
            
            let keyArray = key.components(separatedBy: " ")
            let stepArray = step.components(separatedBy: " ")
            
            for keyElem in keyArray {
                
                if (keyElem.hasPrefix("$")) {
                    parameterNames.append(String(keyElem.suffix(from: keyElem.index(keyElem.startIndex, offsetBy: 1))))
                    var tempParameterString = stepArray[index]
                    index += 1
                    
                    // recognize components within '"' characters as a single parameter value
                    if (tempParameterString.hasPrefix("\"")) {
                        // cut off preceding '"'
                        tempParameterString = String(tempParameterString.suffix(from: tempParameterString.index(tempParameterString.startIndex, offsetBy: 1)))
                        while (!tempParameterString.hasSuffix("\"")) {
                            // add to value until closing '"' is detected
                            tempParameterString = "\(tempParameterString) \(stepArray[index])"
                            index += 1
                        }
                        // remove closing '"'
                        tempParameterString = String(tempParameterString.prefix(tempParameterString.count - 1))
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
                        for _ in 0..<repetitions {
                            self.perform(Selector.init("\(selectorString):"), with: app)
                        }
                        return true
                    }
                }
                
                // if there is a single parameter in the test sentence, a selector is performed
                // whos second parameter's name equals the behaviour-parameter's name
                
                if (parameterNames.count == 1) {
                    if let selectorString = dict[key] {
                        for _ in 0..<repetitions {
                            self.perform(Selector.init("\(selectorString):\(parameterNames[0]):"), with: app, with: parameterValues[0])
                        }
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
                        for _ in 0..<repetitions {
                            self.perform(Selector.init("\(selectorString):parameters:"), with: app, with: parameterDictionary)
                        }
                        return true
                    }
                }
                return false
            }
        }
        return false
    }
    
    
    // MARK: - helper function
    
    func waitForElementToAppear(element: XCUIElement) {
        let predicate = NSPredicate(format: "exists == true")
        expectation(for: predicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func waitForElementToDisappear(element: XCUIElement) {
        let predicate = NSPredicate(format: "exists == false")
        expectation(for: predicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 5.0, handler: nil)
    }

}
