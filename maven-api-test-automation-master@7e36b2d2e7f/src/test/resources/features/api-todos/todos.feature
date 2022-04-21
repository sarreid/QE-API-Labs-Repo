@TODOS-API
Feature: Test /todos API

  Background:
    Given def todo1Details = read('classpath:json/todos-1.json')
    And karate.embed(karate.pretty(todo1Details), 'application/json')

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @LIST
  Scenario: [CNNNNN] - Verify getting a list of todos

    Given url jsonPlaceHolderUrl
    And path '/todos'
    When method GET
    Then status 200
    And match each response ==
      """
        {
          "id": '#number',
          "userId": '#number',
          "title": '#string',
          "completed": '#boolean'
        }
      """
    And match response contains todo1Details

  @POST
  Scenario: [CNNNNN] - Add a new todo
    Given url jsonPlaceHolderUrl
    And def values =
    """
      {
        userId: '#(todo1Details.userId)',
        title: "New todo",
        completed: false,
      }
    """
    And path '/todos'
    And request values
    When method POST
    And karate.embed(karate.pretty(response), 'application/json')
    Then status 201
    And match response contains { "id": '#number' }
    And set values.id = response.id
    And match response == values
    # NOTE: JSONPlaceHolder fakes POST, PUT & DELETE responses, so this item has not been actually
    # added, and thus cannot be retrieved using GET /posts/{id}

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @SMOKE
  Scenario: [CNNNNN] - Verify getting a specific todo

    Given url jsonPlaceHolderUrl
    And path '/todos/' + todo1Details.id
    When method GET
    Then status 200
    And match response == todo1Details

  @NEGATIVE
  Scenario: [CNNNNN] - Verify getting a specific todo using an ID which does not exist returns 404
    Given url jsonPlaceHolderUrl
    And path '/todos/2147483645'
    When method GET
    Then status 404
    And match response == {}

  @NEGATIVE
  Scenario: [CNNNNN] - Verify getting a specific todo using an invalid ID returns 404
    Given url jsonPlaceHolderUrl
    And path '/todos/blahblah'
    When method GET
    Then status 404
    And match response == {}
