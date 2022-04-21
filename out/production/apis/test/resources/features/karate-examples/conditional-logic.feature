@KARATE-EXAMPLES
Feature: Conditional examples

  @RAND-USER-EMAIL
    Scenario: Check random user's email
    #
    # Example of conditional logic within scenario
    # For more information see https://github.com/intuit/karate#conditional-logic
    #
    Given def userId = fakeData.random(1, 5)
    And eval
    """
      if (userId === 1) {
        email = "Sincere@april.biz"
      } else if (userId === 2) {
        email = "Shanna@melissa.tv"
      } else if (userId === 3) {
        email = "Nathan@yesenia.net"
      } else if (userId === 4) {
        email = "Julianne.OConner@kory.org"
      } else if (userId === 5) {
        email = "Lucio_Hettinger@annie.ca"
      } else {
        throw new Error("UserId " + userId + " is not known")
      }
      // context is local to this eval, ensure that the email value is set within the scenario's context
      karate.set('email', email)
    """
    When def data = call read('classpath:shared/get-user-email.feature') { userId: #(userId) }
    Then match data.email == email
