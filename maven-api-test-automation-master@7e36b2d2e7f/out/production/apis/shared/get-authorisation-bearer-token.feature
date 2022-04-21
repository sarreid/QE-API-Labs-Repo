Feature: Get authorisation bearer token

  Scenario: Get authorisation bearer token
    #
    # Retrieve authorisation bearer token value here.
    #
    # Replace the steps in this example to retrieve actual  JWT authorisation bearer token to be
    # used within your project.
    #
    # This example includes a static JWT token value taken from https://jwt.io/
    #
    # This shared scenario returns the following:
    #
    #   token - Actual token value
    #   authorisation - Actual 'Authorization' header value
    #   headers - which contains authorization using the bearer token
    #
    Given def token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
    And def authorisation = 'Bearer ' +  token
    Then def headers =
    """
    {
      Authorization: '#(authorisation)'
    }
    """
