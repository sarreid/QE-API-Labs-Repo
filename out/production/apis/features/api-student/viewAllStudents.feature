@STUDENT-API
Feature: Test /Student API/ View all students

  Background:
    * def students = call read('classpath:Features/api-student/createNewStudent.feature@201Response')
    * def authToken = students.authToken
    * def studentDetails = students.studentDetails
    * def studentID = students.studentID
    Given url 'http://localhost:8500'

    Given def user1Details = read('classpath:json/users-1.json')
    And karate.embed(karate.pretty(user1Details), 'application/json')

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail
  @LIST
  Scenario: View all students - Return 200 with response
    Given header Client-id = !null
    Given header Authorization = authToken
    And path '/students'
    When method GET
    Then status 200

    * def studentDetails = students.studentDetails
    * def studentDetailsJSON =

    """
      function() {
        var convert = JSON.parse(studentDetails)
        return convert
      }
    """

    * def studentDetails = studentDetailsJSON()
    And match response.students contains
    """
      {
      "students": [
           {
           "id": "studentID",
           "firstName": "#(studentDetails.firstName())",
           "lastName": "#(studentDetails.lastName())",
           "nationality": "#(studentDetails.nationality())",
           "dateOfBirth": "#(studentDetails.dateOfBirth())",
           "email": "#(studentDetails.emailAddress())",
           "mobileNumber": "#(studentDetails.mobileNumber())"
           }
        ]
      }
    """
    And match response contains userDetails


    # NOTE: JSONPlaceHolder fakes POST, PUT & DELETE responses, so this item ha s not been actually
    # added, and thus cannot be retrieved using GET /posts/{id}

  # Put the TestRail test case Id as the prefix of scenario name so that the result can be updated in TestRail

  @NEGATIVE
  Scenario: Invalid client-id - Return 401 with response
    Given header Client-Id = null
    Given header Authorization = authToken
    And path '/students'
    When method GET
    Then status 401

    And match response ==
      """
      {
      "message": "Unauthorized request."
      }
      """
  @NEGATIVE
  Scenario: Invalid/missing client-id or authorization - Return 401 with response
    Given header Client-Id = !null
    Given header Authorization = !authToken
    And path '/students'
    When method GET
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
    Given header Authorization = authToken
    And path '/'
    When method GET
    Then status 502
