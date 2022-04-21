package utils.util;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import com.intuit.karate.Logger;

import org.apache.commons.lang3.StringUtils;

public class Support {
    protected static Logger logger = new Logger();

    private Support() {
        // Static methods only - do not allow this class to be instantiated
        throw new IllegalStateException();
    }

    /**
     * Internal method to get property value, and if blank, return default
     * NOTE: Different to System.getProperty(name, defaultValue), as this returns default value if system property is defined
     * and is blank. 
     * @param name Name of system property
     * @param defaultValue Default value, if property value is blank 
     * @return Property value, or default if not defined or blank
     */
    private static String getPropertyValue(final String name, final String defaultValue) {

        String value = System.getProperty(name);

        if (StringUtils.isBlank(value)) {
            value = defaultValue;
        }

        return value;
    }

    /**
     * Retrieves system property value as a string
     * @param name Name of system property
     * @return System property value (or null if not defined)
     */
    public static String getProperty(final String name) {

        String value = System.getProperty(name);

        logger.info("getProperty('{}') = '{}' [string]", name, value);

        return value;
    }

    /**
     * Retrieves system property value as a string
     * @param name Name of system property
     * @param defaultValue Default value if system property not default
     * @return System property value
     */
    public static String getProperty(final String name, final String defaultValue) {

        String value = getPropertyValue(name, defaultValue);

        logger.info("getProperty('{}', '{}') = '{}' [string]", name, defaultValue, value);

        return value;
    }

    /**
     * Retrieves system property value as an integer
     * @param name Name of system property
     * @param defaultValue Default value if system property not default
     * @return System property value
     */
    public static int getProperty(final String name, final int defaultValue) {

        final String propertyValue = getPropertyValue(name, Integer.toString(defaultValue));
        int value;

        try {
            value = Integer.parseInt(propertyValue);
        } catch (final NumberFormatException e) {
            value = defaultValue;
        }

        logger.info("getProperty('{}', {}) = {} [int]", name, defaultValue, value);

        return value;
    }

    /**
     * Parse a string and return true or false, if value is "true" or "false", otherwise null
     * @param value String value to parse
     * @return Boolean value (or null if value is not true or false)
     */
    private static Boolean parseBoolean(final String value) {
        final boolean[] booleanValues = { true, false };
        for (final boolean booleanValue : booleanValues) {
            if (StringUtils.equalsIgnoreCase(value, Boolean.toString(booleanValue))) {
                return booleanValue;
            }
        }
        return null;
    }

    /**
     * Retrieves system property value as a boolean
     * @param name Name of system property
     * @param defaultValue Default value if system property not default
     * @return System property value
     */
    public static boolean getProperty(final String name, final boolean defaultValue) {

        final String propertyValue = getPropertyValue(name, Boolean.toString(defaultValue));

        final Boolean propValue = parseBoolean(propertyValue);

        final boolean value = (propValue == null) ? defaultValue : propValue;

        logger.info("getProperty('{}', {}) = {} [boolean]", name, defaultValue, value);

        return value;
    }

    /**
     * Quote the values in a list
     * @param values List of values
     * @return String of quoted values within list
     */
    private static String quoteValues(final List<String> values) {
        if (values == null) {
            return "";
        }

        if (values.size() == 0) {
            return "[]";
        }

        return "[ '" + String.join("', '", values) + "' ]";
    }

    /**
     * Retrieves system property value specified as a comma separated list of strings
     *
     * @param name Name of system property
     * @param defaultValue Default value if system property not default
     * @param delimiter Delimiter to split string on
     * @return List of string values
     */
    public static List<String> getPropertyList(final String name, final String defaultValue, final String delimiter) {

        final String value = getPropertyValue(name, defaultValue);

        final List<String> values = StringUtils.isBlank(value) ? new ArrayList<>() : Arrays.asList(value.split(delimiter));

        logger.info("getProperty('{}', '{}', '{}') = {}", name, defaultValue, delimiter, quoteValues(values));

        return values;
    }

    /**
     * Retrieves system property value specified as a comma separated list of strings
     *
     * @param name Name of system property
     * @param defaultValue Default value if system property not default
     * @return List of string values
     */
    public static List<String> getPropertyList(final String name, final String defaultValue) {
        return getPropertyList(name, defaultValue, ",");
    }

    /**
     * Retrieves system property value specified as a comma separated list of strings
     *
     * @param name Name of system property
     * @return List of string values
     */
    public static List<String> getPropertyList(final String name) {
        return getPropertyList(name, null, ",");
    }
}
