@SHOPPINGCART-API
Feature: Test /shoppingcart API

  Background:
    Given url 'http://localhost:8500/'
#    Given def user1Details = read('classpath:json/users-1.json')
#    And karate.embed(karate.pretty(user1Details), 'application/json')

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @LIST
  Scenario: [CNNNNN] - Verify getting a list of users
    Given header Client-Id = "DPE-QE"
    And path '/shoppingcart/items'
    And param Type = "Fresh"
    And param Discount = "Applied"
    When method GET
    Then status 200
    And match each response ==
    """
    {
      "basket": [
        {
          "name": "Milk",
          "quantity": "2",
          "price": "$4"
         },
        {
          "name": "Bread",
          "quantity": "1",
          "price": "$5"
        },
        {
          "name": "Eggs",
          "quantity": "1",
          "price": "$6.5"
        }
      ]
    }
    """

  @SMOKE
  Scenario: Client Id missing or invalid - Return 401 with response
    Given header Client-Id = !"DPE-QE"
    And path '/shoppingcart/items'
    And param Type = "Fresh"
    And param Discount = "Applied"
    When method GET
    Then status 401
    And match each response ==
    """
    {
      "message": "Unauthorized request! Client-Id is missing or invalid."
    }
    """

  @NEGATIVE
  Scenario: Type !- "Fresh" OR Discount !="Applied" OR either is missing - Return 400 with response
    Given header Client-Id = "DPE-QE"
    And path '/shoppingcart/items'
    And param Type != "Fresh"
    And param Discount != "Applied"
    When method GET
    Then status 400
    And match each response ==
    """
    {
    "message": "Invalid request! Parameters are missing or invalid."
    }
    """

  @NEGATIVE
  Scenario: Other errors - Return 502 with response
    Given header Client-Id = "DPE-QE"
    And path '/'
    And param Type = "Fresh"
    And param Discount = "Applied"
    When method GET
    Then status 502