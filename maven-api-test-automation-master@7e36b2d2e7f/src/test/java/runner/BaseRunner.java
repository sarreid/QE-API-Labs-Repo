package runner;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.After;
import org.junit.Assert;
import utils.testrail.exceptions.NoTestRailUrlException;
import utils.testrail.exceptions.ProjectNotFoundException;
import utils.testrail.handlers.TestRailIntegrationImp;
import java.io.IOException;

public class BaseRunner {

    final String path;
    final String tags;
    final int threadCount;

    public BaseRunner(final String path, final String tags, final int threadCount) {
        this.path = path;
        this.tags = tags;
        this.threadCount = threadCount;
    }

    @After
    public void updateTestRail() throws ProjectNotFoundException, NoTestRailUrlException, IOException {
        TestRailIntegrationImp.update();
    }

    protected void runTests() {
        Results results = Runner.path(path).tags(tags).parallel(threadCount);
        Assert.assertTrue(results.getErrorMessages(), results.getFailCount() == 0);
    }
}
