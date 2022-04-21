package runner.student;

import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(Karate.class)
public class ApiViewStudentDetailsRunner extends BaseRunner {
    public ApiViewStudentDetailsRunner() {
        super("classpath:features/api-users", "~@ignore", 5);
    }
    @Test
    public void run() {
        runTests();
    }
}
