package runner;
// FULFILLING LAB GOAL R1 - Setup1: (status: failed, max achievement score: 6/7)
/*
    Unable to fulfil lab goal due to missing packages which for some reason did not install upon project startup
 */

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.After;
import org.junit.Assert;
import utils.testrail.exceptions.NoTestRailUrlException;
import utils.testrail.exceptions.ProjectNotFoundException;
import utils.testrail.handlers.TestRailIntegrationImp;

import java.io.IOException;

import org.junit.runner.RunWith;
import com.intuit.karate.junit4.Karate;


@RunWith(Karate.class)
public class mapDataRunner {

    final String path;
    final String tags;
    final int threadCount;

    public mapDataRunner(final String path, final String tags, final int threadCount) {
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
