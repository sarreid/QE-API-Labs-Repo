@KARATE-EXAMPLES
Feature: Karate examples

  @GET-USER-EMAIL
  Scenario: Example of calling shared feature file and passing values to it
    # Verify user #1's email address
    Given def data = call read('classpath:shared/get-user-email.feature') { userId: 1 }
    Then match data.email == "Sincere@april.biz"
    # Verify user #4's email address
    Given def data = call read('classpath:shared/get-user-email.feature') { userId: 4 }
    Then match data.email == "Julianne.OConner@kory.org"
