//
//  TestAppUITests.swift
//  TestAppUITests
//
//  Created by Christian Klaproth on 04.12.15.
//  Copyright © 2015 Christian Klaproth. All rights reserved.
//

extension SwiftBehaveTest {
    
    func mappingFromPlist() -> Dictionary<String, String> {
        
        var mapping: Dictionary<String, String> = Dictionary()
        
        mapping["the main view is shown"] = "givenMainView"
        mapping["I tap the add button"] = "whenTapAddButton"
        mapping["I expect to see $count items"] = "thenCheckItemCount"
        mapping["I tap on item at position $position"] = "whenTapItemAtPosition"
        mapping["I expect to see the details"] = "thenDetailsVisible"
        mapping["I delete the item at position $position"] = "whenDeleteItemAtPosition"
        
        return mapping
    }
    
    // MARK: -
    // MARK: BDD functions

    func givenMainView(_ app: XCUIApplication) {
        
        let detailNavigationBar = app.navigationBars["Detail"]
        if (detailNavigationBar.exists) {
            detailNavigationBar.buttons.element(boundBy: 0).tap()
        }
        
        let masterNavigationBar = app.navigationBars["Master"]
        
        XCTAssert(masterNavigationBar.exists, "main view could not be opened")
    }
    
    func whenTapAddButton(_ app: XCUIApplication) {
        
        app.buttons["Add"].tap()
    }
    
    func thenCheckItemCount(_ app: XCUIApplication, count: String) {
        
        let expectedCount = UInt(count)!
        let actualCount = app.tables.element(boundBy: 0).cells.count
        
        XCTAssert(expectedCount == actualCount, "actual item count (\(actualCount)) does not match expected item count (\(expectedCount))")
    }
    
    func whenTapItemAtPosition(_ app: XCUIApplication, position: String) {
        
        let index = UInt(position)! - 1
        app.tables.element(boundBy: 0).cells.element(boundBy: Int(index)).tap()
    }
    
    func thenDetailsVisible(_ app: XCUIApplication) {
        
        let detailNavigationBar = app.navigationBars["Detail"]
        
        XCTAssert(detailNavigationBar.exists, "details not shown")
    }
    
    func whenDeleteItemAtPosition(_ app: XCUIApplication, position: String) {
        
        app.buttons["Edit"].tap()
        
        let index = UInt(position)! - 1
        // delete
        app.tables.element(boundBy: 0).cells.element(boundBy: Int(index)).buttons.element(boundBy: 0).tap()
        // confirm
        app.tables.element(boundBy: 0).cells.element(boundBy: Int(index)).buttons["Delete"].tap()
        
        app.buttons["Done"].tap()
    }
    
}
