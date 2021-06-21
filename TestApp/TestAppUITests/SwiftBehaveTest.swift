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
        
        var storyFileContent: Array<String> = []
        
        if let fullpath = Bundle(for: SwiftBehaveTest.self).path(forResource: filename, ofType: "story") {
            do {
                let text = try String(contentsOfFile: fullpath, encoding: .utf8)
                storyFileContent = text.components(separatedBy: "\n")
            } catch _ as NSError {
                print("error reading story file \(filename)")
                return Array.init()
            }
        }
        
        var currentName = ""
        var currentSteps = Array<String>()
        var tableInProgress = false
        var currentParams = Array<Dictionary<String, String>>()
        var currentTableKeys = Array<String>() // array containing table headers
        var returnArray = [Any]()
        
        for currentTextLine in storyFileContent {
            
            if currentTextLine.count == 0 || currentTextLine.hasPrefix("Narrative:") || currentTextLine.hasPrefix("#") {
                // ignore empty lines, comments and introducing narrative line
                continue
            }
            
            if currentTextLine.hasPrefix("Examples:") {
                // start parameter table
                tableInProgress = true
                continue
            }
            
            if currentTextLine.hasPrefix("|") {
                // table will work even without introducing "Examples:"
                tableInProgress = true
                if currentTableKeys.count == 0 {
                    // extract row as keys
                    currentTextLine.components(separatedBy: "|").forEach {
                        currentTableKeys.append($0.trimmingCharacters(in: .whitespaces))
                    }
                } else {
                    // extract row as values
                    var values = [String]()
                    currentTextLine.components(separatedBy: "|").forEach {
                        values.append($0.trimmingCharacters(in: .whitespaces))
                    }
                    var row = Dictionary<String, String>()
                    for index in 0...currentTableKeys.count-1 {
                        row[currentTableKeys[index]] = values[index]
                    }
                    currentParams.append(row)
                }
                continue
            }
            
            if currentTextLine.hasPrefix("Scenario: ") || currentTextLine.hasPrefix("Scenario Outline: ") {
                
                // are we currently building a scenario?
                if currentName.count > 0 {
                    // then finish the current scenario...
                    let scenarios = finishScenarioOrOutline(name: currentName, steps: currentSteps, params: currentParams)
                    if tableInProgress {
                        currentTableKeys.removeAll()
                        currentParams.removeAll()
                        tableInProgress = false
                    }
                    currentSteps.removeAll()
                    returnArray.append(contentsOf: scenarios)
                }
                
                // ...and start a new scenario
                currentName = currentTextLine.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
                print("Found start of test scenario '\(currentName)'")
                continue
            }
            
            // treat line as normal test step
            currentSteps.append(currentTextLine)
        }
        
        // add the last (or single) scenario, if one was found
        if currentName.count > 0 {
            // then finish the current scenario(s)...
            returnArray.append(contentsOf: finishScenarioOrOutline(name: currentName, steps: currentSteps, params: currentParams))
            // no need of clean up, methods ends anyway
        }
        
        print("Teststory '\(filename)' with \(returnArray.count) scenarios created.")
        
        return returnArray
    }
    
    /**
     * Finish a single scenario or a scenario outline (depending on the number of parameters given.
     */
    fileprivate static func finishScenarioOrOutline(name: String, steps: Array<String>, params: Array<Dictionary<String, String>>) -> [Any] {
        var scenarioArray = [Any]()
        
        if params.count == 0 {
            let scenario = Scenario()
            scenario.scenarioName = name
            scenario.steps = steps

            print("Adding scenario '\(scenario.scenarioName!)' with \(steps.count) steps.")

            scenarioArray.append(scenario)
        } else {
            var exampleCount = 1
            for paramDict in params {
                let scenario = Scenario()
                scenario.scenarioName = "\(name) \(exampleCount)"
                scenario.steps = replace(params: paramDict, in: steps)

                print("Adding scenario '\(scenario.scenarioName!)' with \(steps.count) steps.")

                scenarioArray.append(scenario)
                exampleCount = exampleCount + 1
            }
        }
        
        return scenarioArray
    }
    
    fileprivate static func replace(params: Dictionary<String, String>, in steps: Array<String>) -> [String] {
        // check each parameter in each step
        var replacedSteps = [String]()
        for step in steps {
            var replacingStep = step
            for key in params.keys {
                replacingStep = replacingStep.replacingOccurrences(of: "<\(key)>", with: params[key]!)
            }
            replacedSteps.append(replacingStep)
        }
        return replacedSteps
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
