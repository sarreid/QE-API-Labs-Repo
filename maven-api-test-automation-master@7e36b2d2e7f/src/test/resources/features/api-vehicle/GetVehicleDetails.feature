@VEHICLE-API
Feature: Test /vehicle API/Get vehicle details - Simple method

  Background:
    Given url 'http://localhost:8500/'
    And path 'data/regos'
    When method GET
    Then status 200
    * def values = response.data
    * def data = karate.map(values, function(value, index) { return { registrationNumber: value} })

# FULFILLING LAB GOAL R4 - Functional1: (status: achieved)
    # When a valid registration number is provided, the system will return the details of the vehicle.
  @200-Response
  Scenario Outline: Return vehicle details - Return 200 with response
    Given path '/data/<registrationNumber>/details'
    When method GET
    Then status 200
    Examples:
    | data |

# FULFILLING LAB GOAL R5 - Functional2: (status: achieved)
    # When an invalid registration number is provided, the system will return the message saying "No vehicle found!"
  @404-Response
  Scenario Outline: Incorrect registration - Return 404 with response
    Given path '/data/<!registrationNumber>/details'
    When method GET
    Then status 404
    And match response ==
    """
      {
        "message": "No vehicle found!"
      }
    """
    Examples:
      | data |

  @502-Response
  Scenario: Other errors - Return 502
    Given path '/'
    When method GET
    Then status 502
