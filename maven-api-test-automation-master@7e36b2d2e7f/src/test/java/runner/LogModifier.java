package runner;

import com.intuit.karate.http.HttpLogModifier;
import org.apache.commons.lang.StringUtils;

/**
 * Log modifier for Karate
 *
 * Prevent Authorization header values from being logged
 */
public class LogModifier implements HttpLogModifier {

  public static final LogModifier instance = new LogModifier();

  // Prevent new instance of this being generated - static instance should be used
  private LogModifier() {
    super();
  }

  @Override
  public boolean enableForUri(final String uri) {
    return true;
  }

  // NOTE: Uncomment @Override when Karate 0.9.6 or later iis being used
  // @Override
  public String uri(final String uri) {
    return uri;
  }

  @Override
  public String header(final String header, final String value) {
    final String basic = "Basic ";
    if (StringUtils.equalsIgnoreCase(header, "Authorization") && StringUtils.startsWithIgnoreCase(value, basic)) {
      // Do not show any authorisation values when Basic authorisation is being used
      return basic + "***";
    }
    return value;
  }

  @Override
  public String request(final String uri, final String request) {
    return request;
  }

  @Override
  public String response(final String uri, final String response) {
    return response;
  }
}