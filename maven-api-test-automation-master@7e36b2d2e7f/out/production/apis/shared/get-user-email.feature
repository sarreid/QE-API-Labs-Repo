Feature: Get user email

  Scenario: Get user email
    #
    # Given user ID, via userId (numeric), retrieve the user's email address
    #
    # Usage:
    #
    #   def data = call read('classpath:shared/get-user-email.feature') { userId: 2 }
    #
    Given match userId == '#number'
    And url jsonPlaceHolderUrl
    And path '/users/' + userId
    When method GET
    Then status 200
    And match response contains
    """
      {
        id: '#(userId)',
        email: '#regex ^.+@.+\..+$'
      }
    """
    And def email = get response.email
