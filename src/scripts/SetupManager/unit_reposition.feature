Feature: Unit Reselection and Repositioning During Deployment

  As a player
  I want to reselect a unit that I have already placed on a deployment tile
  So that I can reposition it before confirming the deployment phase

  Background:
    Given the game is in the setup phase
    And the player has selected units available for deployment
    And valid deployment tiles are highlighted
    And the player has placed at least one unit on a deployment tile

  Scenario: Reselecting a deployed unit to reposition it
    Given the player has placed a Blue Mage on tile (3, 5)
    When the player clicks on tile (3, 5)
    Then the Blue Mage is removed from tile (3, 5)
    And the Blue Mage is returned to preview mode
    And the valid deployment tiles are re-highlighted
    And the Blue Mage ghost preview is shown over valid tiles
    And the UI displays a hint saying "Repositioning Blue Mage"

  Scenario: Repositioning a reselected unit to a new valid tile
    Given the Blue Mage is in preview mode after being reselected
    When the player clicks on tile (5, 6)
    Then the Blue Mage is placed on tile (5, 6)
    And the preview mode ends
    And the ghost preview is hidden
    And the unit appears fully visible on the new tile
    And the deployment count is updated

  Scenario: Attempting to reposition to an invalid tile
    Given the Blue Mage is in preview mode after being reselected
    When the player clicks on tile (10, 10)
    And tile (10, 10) is not a valid deployment tile
    Then no unit is placed
    And the UI shows a warning message "Invalid tile for deployment"
    And the Blue Mage remains in preview mode

  Scenario: Canceling a reposition action
    Given the Blue Mage is in preview mode after being reselected
    When the player presses the Escape key
    Then the Blue Mage is returned to the Deployable Units list
    And the preview mode ends
    And the UI reopens the Deployable Units panel
