@USERS-API
Feature: Test /users API

  Background:
    Given def user1Details = read('classpath:json/users-1.json')
    And karate.embed(karate.pretty(user1Details), 'application/json')

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @LIST
  Scenario: [CNNNNN] - Verify getting a list of users
    Given url jsonPlaceHolderUrl
    And path '/users'
    When method GET
    Then status 200
    And match each response ==
    """
      {
        "id": '#number',
        "name": '#string',
        "username": '#string',
        "email": '#string',
        "address": {
          "street": '#string',
          "suite": '#string',
          "city": '#string',
          "zipcode": '#string',
          "geo": {
            "lat": '#regex ^-?\\d+\\.\\d+$',
            "lng": '#regex ^-?\\d+\\.\\d+$'
          }
        },
        "phone": '#string',
        "website": '#string',
        "company": {
          "name": '#string',
          "catchPhrase": '#string',
          "bs": '#string'
        }
      }
    """
    And match response contains user1Details

  @POST
  Scenario: [CNNNNN] - Add a new user
    Given url jsonPlaceHolderUrl
    # http://dius.github.io/java-faker/apidocs/com/github/javafaker/Name.html
    # https://dius.github.io/java-faker/apidocs/com/github/javafaker/Address.html
    # https://dius.github.io/java-faker/apidocs/com/github/javafaker/Internet.html
    # http://dius.github.io/java-faker/apidocs/com/github/javafaker/PhoneNumber.html
    # http://dius.github.io/java-faker/apidocs/com/github/javafaker/Company.html
    And def name = fakeData.name()
    And def address = fakeData.address()
    And def internet = fakeData.internet()
    And def phoneNumber = fakeData.phoneNumber()
    And def company = fakeData.company()
    And def values =
    """
      {
        "name": '#(name.fullName())',
        "username": '#(name.username())',
        "email": '#(internet.emailAddress())',
        "address": {
          "street": '#(address.streetAddress())',
          "suite": "Penthouse",
          "city": '#(address.city())',
          "zipcode": '#(address.zipCode())',
          "geo": {
            "lat": '#(address.latitude())',
            "lng": '#(address.longitude())'
          }
        },
        "phone": '#(phoneNumber.cellPhone())',
        "website": '#(company.url())',
        "company": {
          "name": '#(company.name())',
          "catchPhrase": '#(company.catchPhrase())',
          "bs": '#(company.bs())'
        }
      }
    """
    And path '/users'
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
  Scenario: [CNNNNN] - Verify getting a specific user
    Given url jsonPlaceHolderUrl
    And path '/users/' + user1Details.id
    When method GET
    Then status 200
    And match response == user1Details

  @NEGATIVE
  Scenario: [CNNNNN] - Verify getting a specific user using an ID which does not exist returns 404
    Given url jsonPlaceHolderUrl
    And path '/users/2147483646'
    When method GET
    Then status 404
    And match response == {}

  @NEGATIVE
  Scenario: [CNNNNN] - Verify getting a specific user using an invalid ID returns 404
    Given url jsonPlaceHolderUrl
    And path '/users/blah'
    When method GET
    Then status 404
    And match response == {}
