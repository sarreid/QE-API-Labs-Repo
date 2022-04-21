@KARATE-EXAMPLES
Feature: Transform examples

  @TRANSFORM_ARRAY_STRINGS_ARRAY_OBJECTS
    Scenario: Transform string array to object array
    Given def values =
    """
        [
            'ABC-123',
            'DEF-456'
        ]
    """
    And def data = karate.mapWithKey(values, 'registrationNumber')
    Then print values
    And print data
    And match data ==
    """
    [
        {
            registrationNumber: 'ABC-123'
        },
        {
            registrationNumber: 'DEF-456'
        }
    ]
    """
