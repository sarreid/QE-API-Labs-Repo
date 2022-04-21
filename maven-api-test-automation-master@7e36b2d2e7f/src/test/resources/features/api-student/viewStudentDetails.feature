@STUDENT-API
Feature: Test /Student API/ View student details

  Background:
    Given def user1Details = read('classpath:json/users-1.json')
    And karate.embed(karate.pretty(user1Details), 'application/json')

    * def createdStudent = call read)'classpath:Features/api-student/createNewStudent.feature@201-Response')
    * def authToken = createdStudent.studentToken
    * def studentID = createdStudent.studentID
    Given url 'http://localhost:8500/'


  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @LIST
  Scenario: View student details - Return 200 with response
    Given path '/student/' + studentID + '/details'
    Given header Client-Id = !null
    And header Authorization = authToken
    When method GET
    Then status 200

    * def studentDetails = createdStudent.studentDetails
    * def studentDetailsJSON =

    """
      function()
      {
        var convert = JSON.parse(studentDetails)
        return convert
      }
    """
    * def studentDetails = studentDetailsJSON()
    And match each response ==
    """
      {
      "data": {
           "id": "studentID",
           "firstName": "#(studentDetails.firstName())",
           "lastName": "#(studentDetails.lastName())",
           "nationality": "#(studentDetails.nationality())",
           "dateOfBirth": "#(studentDetails.dateOfBirth())",
           "email": "#(studentDetails.emailAddress())",
           "mobileNumber": "#(studentDetails.mobileNumber())"
        }
      }
    """
    And match response contains user1Details


  @SMOKE
  Scenario: [CNNNNN] - Verify getting a specific user
    Given url jsonPlaceHolderUrl
    And path '/users/' + user1Details.id
    When method GET
    Then status 200
    And match response == user1Details

  @Negative
  Scenario: Invalid client-id - Return 401 response
    Given path '/student/' + studentID + '/details'
    Given header Client-Id = null
    And header Authorization = authToken

    When method GET
    Then status 401
    And match response ==
    """
      {
      "message": "Unauthorized request."
      }
    """


    # NOTE: JSONPlaceHolder fakes POST, PUT & DELETE responses, so this item ha s not been actually
    # added, and thus cannot be retrieved using GET /posts/{id}

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail


  @NEGATIVE
  Scenario: Invalid/missing client-id or authorization - Return 401 with response
    Given path '/student/' + studentID + '/details'
    Given header Client-Id = !null
    And header Authorization = !authToken
    When method GET
    Then status 401
    And match response ==
  """
    {
      "message": "Unauthorized request."
    }
  """

  @NEGATIVE
  Scenario: Id invalid - Return 404 with response
    Given path '/students/' + !studentID + '/details'
    Given header Client-Id = !null
    And header Authorization = authToken
    When method GET
    Then status 404
    And match response ==
  """
  {
    "message": "No student found!"
  }
  """

  @NEGATIVE
  Scenario: Other errors - Return 502
    Given header Client-Id = !null
    Given header Authorization = !authToken
    And path '/'
    When method GET
    Then status 502