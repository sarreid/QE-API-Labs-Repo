@VEHICLE-API
Feature: Test /vehicle API/ Map data
  Background:
    Given url 'http://localhost:8500'
    And path 'data/regos'
    When method GET
    Then status 200
    * def values = response.data
    * def data = karate.map(values, function(value, index) { return { registrationNumber: value} })

# FULFILLING LAB GOAL R6 - Functional3: (status: achieved)
# DATABASE CONSTRUCTION NOTES: CURATION OF THE TEST DATA (i.e. registration numbers') METADATA (i.e. vehicles' details)
    # 1) ensure the data and the metadata which the response returns are correct,
    # 2) ensure the details in the data mapping fields matches what's given in the lab brief data mapping table,
    # 3) this should be automatically done for every element in the Test Data (data/regos), NOT manually done for each individual registration.
# FULFILLING LAB GOAL R7 - Good Practice: (status: achieved)
    # 4) ensure the test scripts are smart enough to adapt the new test data without manual steps, as the test data will be refreshed.
  Scenario Outline: Verify responses for all vehicles

    Given path '/data/<registrationNumber>/details'
    When method GET
    Then status 200
    * def source_data = response
    * def dob_source = $response.owner[*].dob

    Given path '/vehicle/<registrationNumber>/details'
    When method GET
    Then status 200
    * def response_data = response
    * def convertDate =
      """
      function() {
        for (var i = 0; i < response.data.owner.length; i++) {
          var SimpleDateFormat = Java.type('java.text.SimpleDateFormat');
          var sdf = new SimpleDateFormat('dd/MM/yyyy');
          var oldDate = response_data.data.owner[i].dateOfBirth;
          var date = sdf.parse(oldDate);
          sdf.applyPattern('dd MMMM yyyy');
          response_data.data.owner[i].dateOfBirth = sdf.format(date)
        }
        return response_data.data.owner
      }
      """
    * def response_convert = convertDate()

    And match response_data.data.vehicle.year == source_data.year
    And match response_data.data.vehicle.make == source_data.make
    And match response_data.data.vehicle.model == source_data.model
    And match response_data.data.vehicle.transmission == source_data.transmission
    And match response_data.data.vehicle.odometer == source_data.odometer
    And match response_data.data.registration.registrationNumber == source_data.rego
    And match response_data.data.registration.address[*].addressType == $source_data.addressModel[*].addressType
    And match response_data.data.registration.address[*].addressLine1 == $source_data.addressModel[*].address1
    And match response_data.data.registration.address[*].addressLine2 == $source_data.addressModel[*].address2
    And match response_data.data.registration.address[*].state == $source_data.addressModel[*].state
    And match response_data.data.registration.address[*].country == $source_data.addressModel[*].country
    And match response_data.data.owner[*].fullName == $source_data.owner[*]fullName
    And match response_data.data.owner[*].driverLicense == $source_data.owner[*].license
    And match response_data.data.owner[*].isCurrentOwner == $source_data.owner[*].isCurrentOwner
    And match response_convert[*].dateOfBirth == $source_data.owner[*].dob

    Examples:
      | data |