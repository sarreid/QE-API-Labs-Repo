@TOKEN-API
Feature: Test /student API

  Background:
    Given url 'http://localhost:8500/'
    And path '/token'
    * def clientID = !null
    Given header Client-Id = clientID
#    Given def user1Details = read('classpath:json/users-1.json')
#    And karate.embed(karate.pretty(user1Details), 'application/json')

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @200-Response
  Scenario: Generate token - Return 200 with response
    Given request {"key": "quality-engineering"}
    When method POST
    Then status 200
    * def auth_token = response["token"]
    And match response ==
    """
    {
    "token": "#string"
    }
    """

  @400-Response
  Scenario: Incorrect key - Return 400 with response

    Given request {"key": !"quality-engineering"}
    When method POST
    Then status 400
    And match response ==

    """
    {
      "error": "Invalid key!"
    }
    """


  @502-Response
  Scenario: Other errors - Return 502
    Given path '/'
    Given request {"key": !"quality-engineering"}
    When method POST
    Then status 502


