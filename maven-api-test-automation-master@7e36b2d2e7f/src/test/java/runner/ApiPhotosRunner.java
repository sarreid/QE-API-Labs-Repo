package runner;

import org.junit.Test;

public class ApiPhotosRunner extends BaseRunner {

    public ApiPhotosRunner() {
        super("classpath:features/api-photos", "~@ignore", 5);
    }

    @Test
    public void run() {
        runTests();
    }
}
