package utils.util;

import com.github.javafaker.*;
import com.intuit.karate.Logger;
import org.apache.commons.lang3.StringUtils;
import org.junit.Test;
import org.junit.Assert;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class FakeDataTest {

    protected static Logger logger = new Logger();

    /**
     * Verifies that access to the name, address, internet, phone number and company sections of Faker are valid
     * for the locales:
     *
     *      null (default)
     *      Australia
     *      Japan
     */
    @Test
    public void testFakeData() {
        final Locale[] locales = { null, new Locale("en-AU"), Locale.JAPANESE };

        for (final Locale locale : locales) {
            final String language = locale == null ? null : locale.getLanguage();
            final FakeData fakeData = (locale == null) ? new FakeData() : new FakeData(locale);

            final Name name = fakeData.name();
            Assert.assertNotNull(name);
            String value = name.fullName();
            logger.info("{}: name.fullName() = {}", language, value);
            Assert.assertNotNull(value);

            final Address address = fakeData.address();
            Assert.assertNotNull(address);
            value = address.fullAddress();
            logger.info("{}: address.fullAddress() = {}", language, value);
            Assert.assertNotNull(value);

            final Internet internet = fakeData.internet();
            Assert.assertNotNull(internet);
            value = internet.url();
            logger.info("{}: internet.url() = {}", language, value);
            Assert.assertNotNull(value);

            final PhoneNumber phoneNumber = fakeData.phoneNumber();
            Assert.assertNotNull(phoneNumber);
            value = phoneNumber.phoneNumber();
            logger.info("{}: phoneNumber.phoneNumber() = {}",language,  value);
            Assert.assertNotNull(value);

            final Company company = fakeData.company();
            Assert.assertNotNull(company);
            value = company.url();
            logger.info("{}: company.url() = {}", language, value);
            Assert.assertNotNull(value);
        }
    }

    /**
     * Verifies that a value is within the range specified as lower & upper limits
     * @param value Current value
     * @param lowerLimit Lower limit
     * @param upperLimit Upper limit
     */
    private void verify(final int value, final int lowerLimit, final int upperLimit) {
        final String message = "Value " + value + " within " + lowerLimit + ".." + upperLimit;
        Assert.assertTrue(message, (value >= lowerLimit) && (value <= upperLimit));
    }

    /**
     * Tests the use of the random(limit) method for the locales:
     *
     *      null (default)
     *      Australia
     *      Japan
     *
     * And verifies the return value is >= 0 and < upper (does not include upper)
     */
    @Test
    public void testRandom() {
        final String[] languages = { null, "en-AU", "ja" };

        for (final String language : languages) {
            final FakeData fakeData = StringUtils.isBlank(language) ? new FakeData() : new FakeData(language);
            final int retries = 100;

            final int[] upperLimits = {
                    2,
                    3,
                    10,
                    42
            };

            for (final int upperLimit : upperLimits) {
                for (int retry = 0; retry < retries; retry++) {
                    final int value = fakeData.random(upperLimit);
                    logger.info("{}: {}/{} - random({}) = {}", language, retry, retries, upperLimit, value);
                    // Random number generated must be 0..(upperLimit-1)
                    verify(value, 0, upperLimit - 1);
                }
            }
        }
    }

    /**
     * Tests the use of the random(lower, upper) method for the locales:
     *
     *      null (default)
     *      Australia
     *      Japan
     *
     * And verifies the return value is >= lower and <= upper
     */
    @Test
    public void testRandomLowerUpper() {
        final String[] languages = {null, "en-AU", "ch"};

        for (final String language : languages) {
            final FakeData fakeData = StringUtils.isBlank(language) ? new FakeData() : new FakeData(language);
            final int retries = 42;

            final Map<Integer, Integer> limits = new HashMap<Integer, Integer>() {
                /**
                *
                */
                private static final long serialVersionUID = 1L;

                {
                    put(0, 2);
                    put(-3, 3);
                    put(5, 10);
                    put(1, 42);
                }
            };

            for (final Map.Entry<Integer, Integer> entry : limits.entrySet()) {
                final int lowerLimit = entry.getKey();
                final int upperLimit = entry.getValue();
                for (int retry = 0; retry < retries; retry++) {
                    final int value = fakeData.random(lowerLimit, upperLimit);
                    logger.info("{}: {}/{} - random({}, {}) = {}", language, retry, retries, lowerLimit, upperLimit, value);
                    // Random number generated must be lowerLimit..upperLimit
                    verify(value, lowerLimit, upperLimit);
                }
            }
        }
    }
}