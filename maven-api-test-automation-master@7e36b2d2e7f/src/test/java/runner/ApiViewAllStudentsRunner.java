package runner;

import org.junit.Test;
import org.junit.runner.RunWith;
import com.intuit.karate.junit4.Karate;

@RunWith(Karate.class)
public class ApiViewAllStudentsRunner extends BaseRunner {
    public ApiViewAllStudentsRunner() {
        super("classpath:features/api-users", "~@ignore", 5);
    }
    @Test
    public void run() {
        runTests();
    }
}
