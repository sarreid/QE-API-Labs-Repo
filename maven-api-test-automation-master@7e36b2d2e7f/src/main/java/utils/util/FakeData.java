package utils.util;

import com.github.javafaker.Faker;

import java.util.Locale;

/**
 * FakeData
 *
 * Extends Faker (http://dius.github.io/java-faker/apidocs/index.html) to provide additional random()
 * methods.
 */
public class FakeData extends Faker {

  public FakeData() {
    super(new Locale("en-AU"));
  }

  public FakeData(final String language) {
    super(new Locale(language));
  }

  public FakeData(final Locale locale) {
    super(locale);
  }

  public int random(final int max) {
    return this.random(0, max - 1);
  }

  public int random(final int min, final int max) {
    return this.number().numberBetween(min, max);
  }
}
