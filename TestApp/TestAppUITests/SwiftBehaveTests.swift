//
//  SwiftBehaveTests.swift
//
//  Created by Christian Klaproth on 01.12.15.
//  Copyright (c) 2015 Christian Klaproth. All rights reserved.
//

import XCTest

public extension XCTestCase {
    
    public func testStories() {
        
        let mapping = self.mappingFromPlist()
        
        let app = XCUIApplication()

        for filename in self.listStoryFiles() as! Array<String> {
        
            var testArray: Array<String> = []
            let fullpath = NSBundle(forClass: self.dynamicType).pathForResource(filename, ofType: "story")!
            do {
                let text = try String(contentsOfFile: fullpath, encoding: NSUTF8StringEncoding)
                testArray = text.componentsSeparatedByString("\n")
            } catch _ as NSError {
                print("error reading story file \(filename)")
                return
            }
            
            print("### Running test '\(filename)")
            app.launch()
            
            for testStep in testArray {
                if (testStep.characters.count == 0) {
                    continue
                }
                
                if (testStep.hasPrefix("Scenario: ")) {
                    print("Start test scenario '\(testStep.substringFromIndex(testStep.startIndex.advancedBy(10)))'")
                    continue
                }
                
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
            
            app.terminate()
        }
    }
    
    func listStoryFiles() -> Array<AnyObject> {
        var storyFileNames: Array<String> = []
        let fileManager = NSFileManager.defaultManager()
        let bundleURL = NSBundle(forClass: self.dynamicType).bundleURL
        do {
            let contents = try fileManager.contentsOfDirectoryAtURL(bundleURL, includingPropertiesForKeys: [], options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
         
            for url in contents {
                let last = url.lastPathComponent!
                if (last.hasSuffix(".story")) {
                    let filename = last.substringToIndex(last.endIndex.advancedBy(-6))
                    
                    print("add story file \(filename)")
                    
                    storyFileNames.append(filename)
                }
            }
            
        } catch _ as NSError {
            print("story files not found")
        }
        
        return storyFileNames
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
                    parameterValues.append(stepArray[index])
                    index += 1
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
    
    public func mappingFromPlist() -> Dictionary<String, String> {
        return Dictionary()
    }
}
