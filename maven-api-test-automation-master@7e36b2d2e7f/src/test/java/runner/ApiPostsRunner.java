package runner;

import org.junit.Test;

public class ApiPostsRunner extends BaseRunner {

    public ApiPostsRunner() {
        super("classpath:features/api-posts", "~@ignore", 5);
    }

    @Test
    public void run() {
        runTests();
    }
}
