package runner;

import org.junit.Test;

public class ApiUsersRunner extends BaseRunner {

    public ApiUsersRunner() {
        super("classpath:features/api-users", "~@ignore", 5);
    }

    @Test
    public void run() {
        runTests();
    }
}
