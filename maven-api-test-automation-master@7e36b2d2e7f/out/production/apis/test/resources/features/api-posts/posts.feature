@POSTS-API
Feature: Test /posts API

  Background:
    # NOTE: callonce is used to ensure that this is only called once for this feature file (not for every scenario)
    Given def auth = callonce read('classpath:shared/get-authorisation-bearer-token.feature')
    And karate.embed(karate.pretty(auth), 'application/json')

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @LIST
  Scenario: [CNNNNN] - Verify getting a list of posts
    Given url jsonPlaceHolderUrl
    And headers auth.headers
    And path '/posts'
    When method GET
    And karate.embed(karate.pretty(response), 'application/json')
    Then status 200
    And match each response ==
      """
        {
          "id": '#number',
          "userId": '#number',
          "title": '#string',
          "body": '#string'
        }
      """
    And match response contains read('classpath:json/posts.json')

  @POST
  Scenario: [CNNNNN] - Add a new post
    Given url jsonPlaceHolderUrl
    And def values =
    """
      {
        title: "Hello ...",
        body: "...there",
        userId: '1'
      }
    """
    And headers auth.headers
    And path '/posts'
    And request values
    When method POST
    And karate.embed(karate.pretty(response), 'application/json')
    Then status 201
    And match response contains { "id": '#number' }
    And set values.id = response.id
    And match response == values
    # NOTE: JSONPlaceHolder fakes POST, PUT & DELETE responses, so this item ha s not been actually
    # added, and thus cannot be retrieved using GET /posts/{id}

  @GET @SMOKE
  Scenario Outline: [CNNNNN] - Verify getting a specific post
    Given url jsonPlaceHolderUrl
    And headers auth.headers
    And path '/posts/' + <id>
    When method GET
    And karate.embed(karate.pretty(response), 'application/json')
    Then status 200
    And match response == __row
  Examples:
    # Load examples data from posts.json file
    | read('classpath:json/posts.json') |

  @NEGATIVE
  Scenario: [CNNNNN] - Verify getting a specific post using an ID which does not exist returns 404
    Given url jsonPlaceHolderUrl
    And headers auth.headers
    And path '/posts/2147483647'
    When method GET
    And karate.embed(karate.pretty(response), 'application/json')
    Then status 404
    And match response == {}

  @NEGATIVE
  Scenario: [CNNNNN] - Verify getting a specific post using an invalid ID returns 404
    Given url jsonPlaceHolderUrl
    And headers auth.headers
    And path '/posts/foobar'
    When method GET
    And karate.embed(karate.pretty(response), 'application/json')
    Then status 404
    And match response == {}
