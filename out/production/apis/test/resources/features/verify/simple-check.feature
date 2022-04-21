@VERIFY @ignore
Feature: Karate & Gatling verification

    #
    # This feature is invoked during the build pipeline to verify both Karate and Gatling functionality
    #
    @CHECK
    Scenario: Simple check to verify Karate is functional
        Given def id = 1
        And url jsonPlaceHolderUrl
        And path "/users/" + id
        When method GET
        Then status 200
        And match response contains { id : '#(id)' }
