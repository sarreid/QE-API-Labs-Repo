package runner;

//import com.intuit.karate.Logger;
//import com.intuit.karate.Results;
//import com.intuit.karate.Runner;

import org.junit.After;
import org.junit.Assert;

//import net.masterthought.cucumber.Configuration;
//import net.masterthought.cucumber.ReportBuilder;
import utils.testrail.exceptions.NoTestRailUrlException;
import utils.testrail.exceptions.ProjectNotFoundException;
import utils.testrail.handlers.TestRailIntegrationImp;
import utils.util.Support;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;
import org.junit.Test;

import java.io.File;
import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

public class TagBasedApiRunner {

    protected static Logger logger = new Logger();

    private static String KARATE_ENV = "karate.env";

    private void log(final String label, final List<String> list) {
        if (list != null && !list.isEmpty()) {
            logger.info("{}: ({})\n- '{}'", label, list.size(), String.join("'\n- '", list));
        } else {
            logger.info("{}: empty", label);
        }
    }

    private void log(final String label, final String value) {
        logger.info("{}: {}", label, value);
    }

    private void log(final String label, final int value) {
        logger.info("{}: {}", label, value);
    }

    @After
    public void updateTestRail() throws ProjectNotFoundException, NoTestRailUrlException, IOException {
        TestRailIntegrationImp.update();
    }

    @Test
    public void runApiTests() {

        final String jsonReportDir = Support.getProperty("apitest.json.report.dir", "./target/surefire-reports");
        final List<String> featurePaths = Support.getPropertyList("apitest.feature.paths", "classpath:features/");
        final List<String> apiTestTags = Support.getPropertyList("apitest.tags", null, "&");
        final int threads = Support.getProperty("apitest.threads", 1);

        //
        // NOTE: Karate takes a list of tags to be executed where
        // each tag must match (implied AND)
        //
        // To only run those tests which match one or more tags, then these tags
        // must be specified as a comma separated list of tags (implied OR).
        //
        // The apitest.tags value is '&' separated list of tags which are then
        // separated by ',', so "@R2&@API" becomes { "@R2", "@API"} which
        // means those tests tagged with @R2 *and* @API, where "@R2,@API" becomes
        // { "@R2,@API" } which is @R2 *or* @API
        //
        final List<String> tags = new ArrayList<>();
        for (final String tag : apiTestTags) {
            if (StringUtils.isNotEmpty(tag)) {
                tags.add(tag);
            }
        }

        /*
         * Tests sometimes requite data to be available within the environment in which the tests
         * will be run.
         *
         * If a specific environment does not contain the required data, a test can be tagged with
         * @NO-DATA-{env} to denote that no data is available within the {env} environment. Any tests
         * tagged with this tag will be ignored. For example:
         *
         *      @NO-DATA-DEV    No data is available within the DEV environment
         *      @NO-DATA-TEST   No data is available within the TEST environment
         *
         * So a test tagged with @NO-DATA-DEV will be ignored when tests are run in the DEV environment,
         * but will be run when tests are run in the TEST environment.
         *
         * If, for whatever reason, no data is available within any environment, use the @NO-DATA tag.
         */
        if (Support.getProperty("apitest.no.data.env", true)) {
            // Ensure that those tests marked with @NO-DATA-{environment} are not processed
            tags.add("~@NO-DATA-" + StringUtils.upperCase(Support.getProperty(KARATE_ENV)));
        }

        if (Support.getProperty("apitest.no.data", true)) {
            // Ensure that those tests marked with @NO-DATA are not processed
            tags.add("~@NO-DATA");
        }

        if (Support.getProperty("apitest.ignore", true)) {
            // Ensure that those tests marked with @ignore, or @IGNORE, are NOT processed (implies AND)
            tags.add("~@ignore");
            tags.add("~@IGNORE");
        }

        log("Features", featurePaths);
        log("Tags", tags);
        log("Report directory", jsonReportDir);
        log("Thread count", threads);

        final Runner.Builder builder = Runner.path(featurePaths);
        if (!tags.isEmpty()) {
            builder.tags(tags);
        }

        if (StringUtils.isNotBlank(jsonReportDir)) {
            builder.reportDir(jsonReportDir);
        }

        final Results results = builder.parallel(threads);

        if (Support.getProperty("apitest.html.report.generate", true)) {
            generateHtmlReport(jsonReportDir);
        }

        if (Support.getProperty("apitest.fail.if.failures", false) && results.getFailCount() > 0) {
            Assert.fail("Failures detected: " + results.getFailCount());
        }
    }

    /**
     * Gets the first value from a list of environment variable names
     * @param names List of environment variable names to check, in order to be checked
     * @return 1st non-blank value
     */
    private String checkVars(final String ... names) {
        for (final String name : names) {
            try {
                final String value = System.getenv(name);
                if (StringUtils.isNotBlank(value)) {
                    return value;
                }
            } catch (final Exception e) {
                // Ignore
            }
        }
        return null;
    }

    /**
     * Gets the name of the current host, using the following:
     *
     *      - InetAddress.getLocalHost().getHostName()
     *      - HOSTNAME environment variable (Unix/Mac)
     *      - COMPUTERNAME environment variable (Windows)
     *      - UNKNOWN
     *
     * @return Name of host to be used
     */
    private String getHostName() {
        try {
            // NOTE: 'InetAddress.getLocalHost().getHostName()' may fail
            // See https://stackoverflow.com/questions/7348711/recommended-way-to-get-hostname-in-java
            return InetAddress.getLocalHost().getHostName();
        } catch (final UnknownHostException e) {
            // ignore
        }

        final String value = checkVars("HOSTNAME",      // Unix/Mac
                                       "COMPUTERNAME"   // Windows
                                       );
        if (StringUtils.isNotBlank(value)) {
            return value;
        }
        return "UNKNOWN";
    }

    /**
     * Gets the name of the current user, using the following:
     *
     *      - USER environment variable (Unix/Mac)
     *      - USERNAME environment variable (Windows)
     *      - UNKNOWN
     *
     * @return Name of user to be used
     */
    private String getUserName() {
        final String value = checkVars("USER",      // Unix/Mac
                                       "USERNAME"   // Windows
                                       );
        if (StringUtils.isNotBlank(value)) {
            return value;
        }
        return "UNKNOWN";
    }

    private static class ClassificationDetails {
        protected final String name;
        protected final String caption;
        protected final String defaultValue;

        protected ClassificationDetails(final String name, final String caption, final String defaultValue) {
            this.name = name;
            this.caption = caption;
            this.defaultValue = defaultValue;
        }

        protected ClassificationDetails(final String name, final String caption) {
            this.name = name;
            this.caption = caption;
            this.defaultValue = null;
        }
    }

    private void addClassifications(final Configuration config) {
        final List<ClassificationDetails> items = new ArrayList<>();
        items.add(new ClassificationDetails(KARATE_ENV, "Environment"));
        items.add(new ClassificationDetails("apitest.host", "Host", getHostName()));
        items.add(new ClassificationDetails("apitest.user", "User", getUserName()));
        items.add(new ClassificationDetails("apitest.git.repository.url", "Repository"));
        items.add(new ClassificationDetails("apitest.git.branch", "Branch"));
        items.add(new ClassificationDetails("apitest.git.commit.hash", "Commit"));
        items.add(new ClassificationDetails("apitest.git.dirty", "Dirty"));

        for (final ClassificationDetails item : items) {
            final String value = Support.getProperty(item.name, item.defaultValue);
            final String displayValue = StringUtils.isBlank(value) ? "-" : value;
            config.addClassifications(item.caption, displayValue);
            log(item.caption, displayValue);
        }
    }

    public void generateHtmlReport(String jsonReportDir) {

        // Get list of available Karate JSON report files
        final Collection<File> jsonFiles = FileUtils.listFiles(new File(jsonReportDir), new String[]{"json"}, true);
        if (jsonFiles == null || jsonFiles.isEmpty()) {
            // No JSON report files generated - skip generating report
            return;
        }

        final List<String> jsonPaths = new ArrayList<>(jsonFiles.size());
        jsonFiles.forEach(file -> jsonPaths.add(file.getAbsolutePath()));

        final String htmlReportParentDir = Support.getProperty("apitest.html.report.parent.dir", "./target");
        final String htmlReportTitle = Support.getProperty("apitest.html.report.title", "API Tests");

        final Configuration config = new Configuration(new File(htmlReportParentDir), htmlReportTitle);

        addClassifications(config);

        final ReportBuilder reportBuilder = new ReportBuilder(jsonPaths, config);
        reportBuilder.generateReports();
    }
}
