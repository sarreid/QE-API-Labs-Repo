@PHOTOS-API
Feature: Test /photos API

  Background:
    Given def photo1Details = read('classpath:json/photos-1.json')
    And karate.embed(karate.pretty(photo1Details), 'application/json')

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @LIST
  Scenario: [CNNNNN] - Verify getting a list of photos
    Given url jsonPlaceHolderUrl
    And path '/photos'
    When method GET
    Then status 200
    And match each response ==
      """
        {
          "id": '#number',
          "albumId": '#number',
          "title": '#string',
          "url": '#string',
          "thumbnailUrl": '#string'
        }
      """
    And match response contains photo1Details

  @POST
  Scenario: [CNNNNN] - Add a new photo
    Given url jsonPlaceHolderUrl
    And def values =
    """
      {
        "albumId": "#(photo1Details.albumId)",
        "title": "New photo",
        "url": "https://via.placeholder.com/600/0000FF/FFFFFF",
        "thumbnailUrl": "https://via.placeholder.com/150/0000FF/FFFFFF"
      }
    """
    And path '/photos'
    And request values
    When method POST
    And karate.embed(karate.pretty(response), 'application/json')
    Then status 201
    And match response contains { "id": '#number' }
    And set values.id = response.id
    And match response == values
    # NOTE: JSONPlaceHolder fakes POST, PUT & DELETE responses, so this item ha s not been actually
    # added, and thus cannot be retrieved using GET /posts/{id}

# Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @SMOKE
  Scenario: [CNNNNN] - Verify getting a specific photo
    Given url jsonPlaceHolderUrl
    And path '/photos/' + photo1Details.id
    When method GET
    Then status 200
    And match response == photo1Details

  @BINARY
  Scenario: [CNNNNN] - Get photo details
    # Issue with certificate for via.placeholder.com - so use http so Hoverfly does not complain
    Given def func =
    """
      function(value) {
        return value.replace(/^https/, 'http');
      }
    """
    Given def endpoint = func(photo1Details.url)
    And url endpoint
    When method GET
    Then status 200
    And match responseHeaders['Content-Type'][0] == 'image/png'
    And match responseBytes == read('classpath:images/image.png')

  @BINARY
  Scenario: [CNNNNN] - Get photo thumbnail details
    # Issue with certificate for via.placeholder.com - so use http so Hoverfly does not complain
    Given def func =
    """
      function(value) {
        return value.replace(/^https/, 'http');
      }
    """
    Given def endpoint = func(photo1Details.thumbnailUrl)
    And url endpoint
    When method GET
    Then status 200
    And match responseHeaders['Content-Type'][0] == 'image/png'
    And match responseBytes == read('classpath:images/thumbnail.png')

  @NEGATIVE
  Scenario: [CNNNNN] - Verify getting a specific photo using an ID which does not exist returns 404
    Given url jsonPlaceHolderUrl
    And path '/photos/2147483642'
    When method GET
    Then status 404
    And match response == {}

  @NEGATIVE
  Scenario: [CNNNNN] - Verify getting a specific photo using an invalid ID returns 404
    Given url jsonPlaceHolderUrl
    And path '/photos/foo'
    When method GET
    Then status 404
    And match response == {}
