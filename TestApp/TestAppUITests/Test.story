Narrative: An example story test file.

Scenario: Check initial list is empty
Given the main view is shown
Then I expect to see 0 items

Scenario: Create one item
Given the main view is shown
When I tap the add button
Then I expect to see 1 items

Scenario: Create multiple items
Given the main view is shown
# execute the following step three times
When I tap the add button 3 times
Then I expect to see "3" items

Scenario: Navigate to details
Given the main view is shown
When I tap the add button
And I tap the add button
And I tap on item at position 1
Then I expect to see the details

Scenario: Delete items
Given the main view is shown
When I tap the add button
And I tap the add button
And I delete the item at position 2
Then I expect to see 1 items
