package utils.util;

import org.apache.commons.lang3.StringUtils;
import org.junit.Test;
import org.junit.Assert;

import java.util.*;

public class SupportTest {

    /**
     * Clears specified system property name
     * @param propertyName Name of system property to be cleared
     */
    private void clearSystemProperty(final String propertyName) {
        System.clearProperty(propertyName);
        Assert.assertNull(Support.getProperty(propertyName));
    }

    /**
     * Sets the specified system property to a value (string)
     * @param propertyName Name of system property to be set
     * @param value Value to which system property is set
     */
    private void setSystemProperty(final String propertyName, final String value) {
        if (value == null) {
            clearSystemProperty(propertyName);
            return;
        }
        System.setProperty(propertyName, value);
        Assert.assertEquals(value, Support.getProperty(propertyName));
    }

    /**
     * Sets the specified system property to a value (int)
     * @param propertyName Name of system property to be set
     * @param value Value to which system property is set
     */
    private void setSystemProperty(final String propertyName, final int value) {
        setSystemProperty(propertyName, String.valueOf(value));
    }

    /**
     * Sets the specified system property to a value (boolean)
     * @param propertyName Name of system property to be set
     * @param value Value to which system property is set
     */
    private void setSystemProperty(final String propertyName, final boolean value) {
        setSystemProperty(propertyName, String.valueOf(value));
    }

    /**
     * Verifies use of Support.getProperty() call where a default value is NOT specified
     */
    @Test
    public void testGetPropertyStringNoDefault() {

        final String propertyName = "test.apitest.property.string.no.default";
        final String[] expectedValues = {
                "something",
                "another thing",
                "" // Empty string
        };

        clearSystemProperty(propertyName);

        // Test - property set to expected value - verify this value is returned
        for (final String expectedValue : expectedValues) {
            setSystemProperty(propertyName, expectedValue);
            Assert.assertEquals(expectedValue, Support.getProperty(propertyName));
        }

        clearSystemProperty(propertyName);
    }

    /**
     * Verifies use of Support.getProperty(), which returns a string, call where a default value is specified
     */
    @Test
    public void testGetPropertyString() {

        final String propertyName = "test.apitest.property.string.default";

        final String[] defaultValues = {
                "Default value 1",
                "Default value 2",
                "",
                null
        };

        final String[] expectedValues = {
                "lorem ipsum",
                "Bacon ipsum dolor amet capicola jerky pork belly beef ribs",
                ""
        };

        // Test - property cleared - verify default value returned
        clearSystemProperty(propertyName);
        for (final String defaultValue : defaultValues) {
            Assert.assertEquals(defaultValue, Support.getProperty(propertyName, defaultValue));
        }

        // Test - property set to expected value - verify this value is returned (if not blank)
        for (final String expectedValue : expectedValues) {
            setSystemProperty(propertyName, expectedValue);
            for (final String defaultValue : defaultValues) {
                final String expected = StringUtils.isBlank(expectedValue) ? defaultValue : expectedValue;
                Assert.assertEquals(expected, Support.getProperty(propertyName, defaultValue));
            }
        }

        // Test - property cleared - verify default value returned
        clearSystemProperty(propertyName);
        for (final String defaultValue : defaultValues) {
            Assert.assertEquals(defaultValue, Support.getProperty(propertyName, defaultValue));
        }
    }

    /**
     * Verifies use of Support.getProperty(), which returns an integer, call where a default value is specified
     * Tests when property value contains a valid integer (property value returned) and an invalid integer value (default value returned)
     */
    @Test
    public void testGetPropertyInt() {
        final String propertyName = "test.apitest.property.int.default";

        final int[] defaultValues = {
                42,
                -3,
                0,
                1234
        };

        final int[] expectedValues = {
                111,
                0,
                8954986
        };

        final String[] invalidValues = {
                "blah",
                "",
                "987kjsjdf"
        };

        // Test - property cleared - verify default value returned
        clearSystemProperty(propertyName);
        for (final int defaultValue : defaultValues) {
            Assert.assertEquals(defaultValue, Support.getProperty(propertyName, defaultValue));
        }

        // Test - property set to expected value - verify this value is returned
        for (final int expectedValue : expectedValues) {
            setSystemProperty(propertyName, expectedValue);
            for (final int defaultValue : defaultValues) {
                Assert.assertEquals(expectedValue, Support.getProperty(propertyName, defaultValue));
            }
        }

        // Test - property set to invalid integer value - verify default value is returned
        for (final String invalidValue : invalidValues) {
            setSystemProperty(propertyName, invalidValue);
            for (final int defaultValue : defaultValues) {
                Assert.assertEquals(defaultValue, Support.getProperty(propertyName, defaultValue));
            }
        }

        // Test - property cleared - verify default value returned
        clearSystemProperty(propertyName);
        for (final int defaultValue : defaultValues) {
            Assert.assertEquals(defaultValue, Support.getProperty(propertyName, defaultValue));
        }
    }

    /**
     * Verifies use of Support.getProperty(), which returns a boolean, call where a default value is specified
     * Tests when property value contains a valid boolean (property value returned) and an invalid boolean value (default value returned)
     */
    @Test
    public void testGetPropertyBool() {
        final String propertyName = "test.apitest.property.bool.default";

        final boolean[] defaultValues = {
                true,
                false
        };

        final boolean[] expectedValues = {
                false,
                true
        };

        final String[] invalidValues = {
                "blah",
                "fals",
                "tru",
                "",
                "987kjsjdf"
        };

        // Test - property cleared - verify default value returned
        clearSystemProperty(propertyName);
        for (final boolean defaultValue : defaultValues) {
            Assert.assertEquals(defaultValue, Support.getProperty(propertyName, defaultValue));
        }

        // Test - property set to expected value - verify this value is returned
        for (final boolean expectedValue : expectedValues) {
            setSystemProperty(propertyName, expectedValue);
            for (final boolean defaultValue : defaultValues) {
                Assert.assertEquals(expectedValue, Support.getProperty(propertyName, defaultValue));
            }
        }

        // Test - property set to invalid boolean value - verify default value is returned
        for (final String invalidValue : invalidValues) {
            setSystemProperty(propertyName, invalidValue);
            for (final boolean defaultValue : defaultValues) {
                Assert.assertEquals(defaultValue, Support.getProperty(propertyName, defaultValue));
            }
        }

        // Test - property cleared - verify default value returned
        clearSystemProperty(propertyName);
        for (final boolean defaultValue : defaultValues) {
            Assert.assertEquals(defaultValue, Support.getProperty(propertyName, defaultValue));
        }
    }

    /**
     * Creates a list of a single value
     * @param value Value to be present in list
     * @return List containing value
     */
    private List<String> createListOfOne(final String value) {
        if (StringUtils.isBlank(value)) {
            return new ArrayList<>();
        }
        return new ArrayList<>(Arrays.asList(value));
    }

    /**
     * Creates a list from an array of values (zero or more)
     * @param values Array of values to be added to list
     * @return List of values
     */
    private List<String> createList(final String[] values) {
        if (values == null) {
            return new ArrayList<>();
        }
        return new ArrayList<>(Arrays.asList(values));
    }

    /**
     * Verifies use of Support.getPropertyList() where a default value is NOT specified
     */
    @Test
    public void testGetPropertyListNoDefault() {
        final String propertyName = "test.apitest.property.list.no.default";

        final Map<String, List<String>> testData = new HashMap<String, List<String>>() {
            /**
            *
            */
            private static final long serialVersionUID = 1L;

            {
                final String[] valuesBlah    = { "blah" };
                final String[] values123     = { "one", "two", "three" };
                final String[] values123Dot  = { "one.two.three" };

                put(null,            createList(null));
                put("",              createList(null));
                put("blah",          createList(valuesBlah));
                put("one,two,three", createList(values123));
                put("one.two.three", createList(values123Dot));
            }
        };

        for (Map.Entry<String, List<String>> test : testData.entrySet()) {
            final String input = test.getKey();
            final List<String> expected = test.getValue();

            // Set list value
            setSystemProperty(propertyName, input);

            // Verify expected value is returned
            Assert.assertEquals(expected, Support.getPropertyList(propertyName));

            // Verify expected value is returned when null passed as default
            Assert.assertEquals(expected, Support.getPropertyList(propertyName, null));

            // Ensure than specifying ',' (default) delimiter returns the same
            Assert.assertEquals(expected, Support.getPropertyList(propertyName, null, ","));

            // Delimiter other than ',' will return a list of one item (or no items if input is null/blank)
            final List<String> expectedInput = StringUtils.isBlank(input) ? new ArrayList<String>() : createListOfOne(input);
            Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName, null, "&"));
            Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName, null, "%"));
        }
    }

    /**
     * Verifies use of Support.getPropertyList() where a default value is NOT specified and delimiter is something other than comma (default delimiter)
     */
    @Test
    public void testGetPropertyListNoDefaultDelimNotComma() {
        final String propertyName = "test.apitest.property.list.no.default.delim.not.comma";

        final Map<String, List<String>> testData = new HashMap<String, List<String>>() {
            /**
            *
            */
            private static final long serialVersionUID = 1L;

            {
                final String[] valuesBlah    = { "blah" };
                final String[] values123     = { "one", "two", "three" };
                final String[] values123Dot  = { "one.two.three" };

                put(null,            createList(null));
                put("",              createList(null));
                put("blah",          createList(valuesBlah));
                put("one&two&three", createList(values123));
                put("one.two.three", createList(values123Dot));
            }
        };

        for (Map.Entry<String, List<String>> test : testData.entrySet()) {
            final String input = test.getKey();
            final List<String> expected = test.getValue();

            // Set list value
            setSystemProperty(propertyName, input);

            // Ensure than specifying '&' delimiter returns expected
            Assert.assertEquals(expected, Support.getPropertyList(propertyName, null, "&"));

            // Delimiter other than '&' will return a list of one item (or no items if input is null/blank)
            final List<String> expectedInput = StringUtils.isBlank(input) ? new ArrayList<String>() : createListOfOne(input);
            Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName));
            Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName, null));
            Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName, null, ","));
            Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName, null, "%"));
        }
    }

    /**
     * Verifies use of Support.getPropertyList() where a default value is specified
     */
    @Test
    public void testGetPropertyListDefault() {
        final String propertyName = "test.apitest.property.list.default";

        final Map<String, List<String>> defaultData = new HashMap<String, List<String>>() {
            /**
            *
            */
            private static final long serialVersionUID = 1L;

            {
                final String[] valuesBlah    = { "blah" };
                final String[] values123     = { "one", "two", "three" };
                final String[] values123Dot  = { "one.two.three" };

                put(null,            createList(null));
                put("",              createList(null));
                put("blah",          createList(valuesBlah));
                put("one,two,three", createList(values123));
                put("one.two.three", createList(values123Dot));
            }
        };

        final Map<String, List<String>> testData = new HashMap<String, List<String>>() {
            /**
            *
            */
            private static final long serialVersionUID = 1L;

            {
                final String[] valuesFoobar  = { "foobar" };
                final String[] values123     = { "1", "2", "3" };
                final String[] values123Dot  = { "1.2.3" };

                put(null,            createList(null));
                put("",              createList(null));
                put("foobar",        createList(valuesFoobar));
                put("1,2,3",         createList(values123));
                put("1.2.3",         createList(values123Dot));
            }
        };

        for (Map.Entry<String, List<String>> defaultValue : defaultData.entrySet()) {
            final String defaultInput = defaultValue.getKey();
            final List<String> defaultList = defaultValue.getValue();
            for (Map.Entry<String, List<String>> test : testData.entrySet()) {
                final String input = test.getKey();
                final List<String> list = test.getValue();

                // Set list value
                setSystemProperty(propertyName, input);

                final List<String> expected = StringUtils.isBlank(input) ? defaultList : list;

                // Verify expected value is returned
                Assert.assertEquals(expected, Support.getPropertyList(propertyName, defaultInput));

                // Ensure than specifying ',' (default) delimiter returns the same
                Assert.assertEquals(expected, Support.getPropertyList(propertyName, defaultInput, ","));

                // Delimiter other than ',' will return a list of one item (or no items if input is null/blank)
                final List<String> expectedInput = StringUtils.isBlank(input) ? createListOfOne(defaultInput) : createListOfOne(input);
                Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName, defaultInput, "&"));
                Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName, defaultInput, "%"));
            }
        }
    }

    /**
     * Verifies use of Support.getPropertyList() where a default value is specified and delimiter is something other than comma (default delimiter)
     */
    @Test
    public void testGetPropertyListDefaultDelimNotComma() {
        final String propertyName = "test.apitest.property.list.default.delim.not.comma";

        final Map<String, List<String>> defaultData = new HashMap<String, List<String>>() {
            /**
            *
            */
            private static final long serialVersionUID = 1L;

                {
                final String[] valuesBlah    = { "blah" };
                final String[] values123     = { "one", "two", "three" };
                final String[] values123Dot  = { "one.two.three" };

                put(null,            createList(null));
                put("",              createList(null));
                put("blah",          createList(valuesBlah));
                put("one#two#three", createList(values123));
                put("one.two.three", createList(values123Dot));
            }
        };

        final Map<String, List<String>> testData = new HashMap<String, List<String>>() {
            /**
            *
            */
            private static final long serialVersionUID = 1L;

            {
                final String[] valuesFoobar  = { "foobar" };
                final String[] values123     = { "1", "2", "3" };
                final String[] values123Dot  = { "1.2.3" };

                put(null,            createList(null));
                put("",              createList(null));
                put("foobar",        createList(valuesFoobar));
                put("1#2#3",         createList(values123));
                put("1.2.3",         createList(values123Dot));
            }
        };

        for (Map.Entry<String, List<String>> defaultValue : defaultData.entrySet()) {
            final String defaultInput = defaultValue.getKey();
            final List<String> defaultList = defaultValue.getValue();
            for (Map.Entry<String, List<String>> test : testData.entrySet()) {
                final String input = test.getKey();
                final List<String> list = test.getValue();

                // Set list value
                setSystemProperty(propertyName, input);

                final List<String> expected = StringUtils.isBlank(input) ? defaultList : list;

                // Ensure than specifying '#' delimiter returns expected
                Assert.assertEquals(expected, Support.getPropertyList(propertyName, defaultInput, "#"));

                // Delimiter other than ',' will return a list of one item (or no items if input is null/blank)
                final List<String> expectedInput = StringUtils.isBlank(input) ? createListOfOne(defaultInput) : createListOfOne(input);

                // Verify expected value is returned
                Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName, defaultInput));

                Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName, defaultInput, ","));
                Assert.assertEquals(expectedInput, Support.getPropertyList(propertyName, defaultInput, "%"));
            }
        }
    }
}