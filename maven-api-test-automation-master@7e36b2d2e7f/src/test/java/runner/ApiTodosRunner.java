package runner;

import org.junit.Test;

public class ApiTodosRunner extends BaseRunner {

    public ApiTodosRunner() {
        super("classpath:features/api-todos", "~@ignore", 5);
    }

    @Test
    public void run() {
        runTests();
    }
}
