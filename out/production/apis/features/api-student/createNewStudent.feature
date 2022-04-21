@STUDENT-API
Feature: Test /student API/create new student

  Background:
    * def clientID = !null
    * def authToken = newStudent.authToken
#    And def userDetails = randomDetails.inputDetails
    And def user1Details = read('classpath:json/users-1.json')
#    And def randomDetails = callonce read('classpath:Features/student/[MAKETHISFILE]')
    And karate.embed(karate.pretty(user1Details), 'application/json')

    Given url 'http://localhost:8500/'
    Given path '/student/create'

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @POST
  Scenario: Create a new student - Return 201 with response
    Given header Client-Id = !null
    And header Authorization = authToken

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
    And path '/student/create'
    And request values
    When method POST
    And karate.embed(karate.pretty(response), 'application/json')
    Then status 201
    And match response contains { "id": '#number' }
    And set values.id = response.id
    And match response ==
    """
      {
        "id": '#string',
        "message": "New student was created successfully!"
      }
    """

    # NOTE: JSONPlaceHolder fakes POST, PUT & DELETE responses, so this item has not been actually
    # added, and thus cannot be retrieved using GET /posts/{id}

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail

  @SMOKE
  Scenario: [CNNNNN] - Verify getting a specific user
    Given path '/students/' + user1Details.id
    When method GET
    Then status 200
    And match response == user1Details


  @NEGATIVE
  Scenario: 400 response
    Given header Client-Id = !null
    And header Authorization = authToken
    Given request user1Details
    When method POST
    Then status 400
    And match response ==
    """
    {
    "message": "ERROR! Student exists!"
    }
    """

  @NEGATIVE
  Scenario: Missing or invalid client id - Return 401 response
    Given header Client-Id = !null
    And header Authorization = authToken
    Given header Client-Id = !null
    And request user1Details
    When method POST
    Then status 401
    And match response ==
    """
    {
    "message": "Unauthorized request."
    }
    """

  @NEGATIVE
  Scenario: Invalid token - Return 401 response
    Given header Client-Id = !null
    And header Authorization = !authToken
    And request user1Details
    When method POST
    Then status 401
    And match response ==
    """
    {
    "message": "Unauthorized request."
    }
    """

  @NEGATIVE
  Scenario: Other errors - Return 502
    Given header Client-Id = !null
    Given header Authorization = auth_token
    And request !userDetails
    And path '/student/create'
    When method GET
    Then status 502
