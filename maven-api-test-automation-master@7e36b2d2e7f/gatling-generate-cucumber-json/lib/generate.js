'use strict';

const _ = require('lodash');
const path = require('path');
const fs = require('fs');
const utils = require('./utils');
const validJiraProjects = require('../resources/valid-jira-projects.json');
const template = require('../resources/template.json');

const DEFAULT_GATLING_RESULTS_FOLDER = './target/gatling';
const DEFAULT_OUTPUT_FOLDER = './gatling-cucumber-reports';
const VERSION = _.get(require('../package.json'), 'version') || '1.0.0';

const BASE64 = 'base64';
const TAB_SIZE = 4;

const MIME_TYPE_TEXT = 'text/plain';
const MIME_TYPE_JSON = 'application/json';

const TAG_NONE = '<none>';

//
// Cucumber JSON duration values use nanoseconds as their unit; whereas this script calculates duration in milliseconds.
// Therefore we need to multiply durations by 1,000,000 to convert milliseconds (10^-3) to nanoseconds (10^-9).
//
const DURATION_FACTOR = 1000000;

/**
 * Loads the Gatling results so they can be retrieved using Gatling simulation class name, where
 * output is of the form:
 *
 *      Simulation performance.ExamplesScenario started...
 *
 *      ================================================================================
 *      2021-03-05 14:28:20                                           7s elapsed
 *      ---- Requests ------------------------------------------------------------------
 *      > Global                                                   (OK=21     KO=0     )
 *      > GET /users/{id}                                          (OK=21     KO=0     )
 *
 *      ---- posts ---------------------------------------------------------------------
 *      [######------------                                                        ]  9%
 *                waiting: 75     / active: 16     / done: 9
 *      ================================================================================
 *
 *
 *      ================================================================================
 *      2021-03-05 14:28:22                                          10s elapsed
 *      ---- Requests ------------------------------------------------------------------
 *      > Global                                                   (OK=98     KO=0     )
 *      > GET /users/{id}                                          (OK=98     KO=0     )
 *
 *      ---- posts ---------------------------------------------------------------------
 *      [########################################################################  ] 98%
 *                waiting: 2      / active: 0      / done: 98
 *      ================================================================================
 *
 *
 *      ================================================================================
 *      2021-03-05 14:28:22                                          10s elapsed
 *      ---- Requests ------------------------------------------------------------------
 *      > Global                                                   (OK=100    KO=0     )
 *      > GET /users/{id}                                          (OK=100    KO=0     )
 *
 *      ---- posts ---------------------------------------------------------------------
 *      [##########################################################################]100%
 *                waiting: 0      / active: 0      / done: 100
 *      ================================================================================
 *
 *      Simulation performance.ExamplesScenario completed in 9 seconds
 *      Parsing log file(s)...
 *      Parsing log file(s) done
 *      Generating reports...
 *
 *      ================================================================================
 *      ---- Global Information --------------------------------------------------------
 *      > request count                                        100 (OK=100    KO=0     )
 *      > min response time                                     18 (OK=18     KO=-     )
 *      > max response time                                   5913 (OK=5913   KO=-     )
 *      > mean response time                                  1373 (OK=1373   KO=-     )
 *      > std deviation                                       2381 (OK=2381   KO=-     )
 *      > response time 50th percentile                         43 (OK=43     KO=-     )
 *      > response time 75th percentile                         61 (OK=61     KO=-     )
 *      > response time 95th percentile                       5912 (OK=5912   KO=-     )
 *      > response time 99th percentile                       5913 (OK=5913   KO=-     )
 *      > mean requests/sec                                     10 (OK=10     KO=-     )
 *      ---- Response Time Distribution ------------------------------------------------
 *      > t < 500 ms                                            76 ( 76%)
 *      > 500 ms < t < 750 ms                                    0 (  0%)
 *      > t > 750 ms                                            24 ( 24%)
 *      > failed                                                 0 (  0%)
 *      ================================================================================
 *
 *      Reports generated in 0s.
 *      Please open the following file: ...\api-test-automation-template\target\gatling\examplesscenario-20210305032812736\index.html
 *      Global: 95th percentile of response time is less than or equal to 1000.0 : false
 *      Global: max of response time is less than or equal to 1500.0 : false
 *      Global: percentage of successful requests is 100.0 : true
 *
 * The start of each simulation classes output is 'Simulation {class-name} started...'
 *
 * @param {String} fileName File containing Gatling textual results
 * @returns {Object} Object where key is the Gatling simulation class name, and value is test output
 */
function loadResultsFile(fileName) {

    console.log(`Processing Gatling results file '${fileName}'`);
    const fileLines = fs.readFileSync(fileName, 'utf-8').split(/\r?\n/);

    const results = {};
    let currentLineNumber = 0;
    let name;
    let lines;
    let lineNumber;
    let processingDetails = false;
    const regex = /^Simulation (.+) started\.\.\.$/;
    fileLines.forEach(line => {
        currentLineNumber ++;
        const matches = line.match(regex);
        if (matches) {
            if (processingDetails) {
                results[name] = {
                    name,
                    lineNumber,
                    lines
                };
                processingDetails = false;
            }
            processingDetails = true;
            name = matches[1];
            lines = [ line ];
            lineNumber = currentLineNumber;

            const existing = results[name];
            if (existing) {
                throw new Error(`Gatling results file '${fileName}' contains multiple references to '${name}' - lines ${existing.lineNumber} and ${lineNumber}`);
            }

            console.log(`Found start of simulation '${name}' at line number ${currentLineNumber}`);

        } else if (processingDetails) {
            lines.push(line);
        }
    });

    if (processingDetails) {
        results[name] = {
            name,
            lineNumber,
            lines
        };
    }

    console.log(`Gatling results file '${fileName}' contained information for ${Object.keys(results).length} simulations`);

    return results;
}

/**
 * For the given error message, do the following:
 *
 *      - write 'FAIL: message' to the console
 *      - adds the message to the existing array of errors
 *
 * @param {[String]} errors
 * @param {String} error
 */
function recordError(errors, error) {
    console.log(`FAIL: ${error}`);
    errors.push(error);
}

/**
 * Converts a string, containing a numeric value, into a number
 *
 * @param {String} value String containing numeric value
 * @returns {Number} Numeric value, or undefined, if not a number
 */
function parseNumeric(value) {
    if (value.match(/^\d+$/)) {
        return parseInt(value, 10);
    }
    console.log(`FAIL: Value '${value}' is not numeric`);
    return undefined;
}

/**
 * Loads the performance log data for the simulation, returning the information as an object with the following properties:
 *
 *      name        Simulation class name (as taken from RUN line)
 *      id          Simulation class id (as taken from RUN line)
 *      start       Start time (epoch milliseconds) (as taken from RUN line)
 *      end         End time (epoch milliseconds) (as take from last USER END line)
 *      start       Arrays of lines containing simulation log details
 *
 * Performance log information has the following format (tab delimited data):
 *
 *      ASSERTION	AAMEAAEEAAAAAAAAwFdABwAAAAAAAECPQA==
 *      ASSERTION	AAMEAAEBBwAAAAAAAHCXQA==
 *      ASSERTION	AAMDAAMFAAAAAAAAAFlA
 *      RUN	performance.ExamplesScenario_EXAMPLE_10	examplesscenario-example-10	1615338741381	 	3.0.2
 *      USER	posts	1	START	1615338741630	1615338741630
 *      USER	posts	2	START	1615338742249	1615338742249
 *      USER	posts	3	START	1615338742359	1615338742359
 *      :
 *      USER	posts	99	END	1615338751436	1615338751485
 *      USER	posts	100	START	1615338751530	1615338751530
 *      REQUEST	100		GET /users/{id}	1615338751547	1615338751569	OK
 *      USER	posts	100	END	1615338751530	1615338751569
 *
 *
 * @param {[String]]} errors Array of current errors
 * @param {String} fileName File name containing the simulation log details
 * @returns {Object} Performance log information
 */
function loadPerformanceDetails(errors, fileName) {

    console.log(`Processing performance log file '${fileName}'`);
    const lines = fs.readFileSync(fileName, 'utf-8').split(/\r?\n/);

    const VALUES = 6;
    let name = undefined;
    let id = undefined;
    let start = undefined;
    let end = undefined;

    lines.forEach(line => {
        const values = line.split(/\t/);
        if (values.length >= VALUES && values[0] === 'RUN') {
            name = values[1];
            id = values[2];
            start = parseNumeric(values[3]);
        }
        if (values.length >= VALUES && values[0] === 'USER' && values[3] === 'END') {
            // Last end time value will be taken as the end time of the simulation
            end = parseNumeric(values[5]);
        }
    });

    if (!name) {
        recordError(errors, `Simulation name not found within '${fileName}'`);
    }
    if (!id) {
        recordError(errors, `Simulation id not found within '${fileName}' (using name)`);
        id = name;
    }
    if (!start) {
        recordError(errors, `Simulation start time not found within '${fileName}'`);
    }
    if (!end) {
        recordError(errors, `Simulation end time not found within '${fileName}'`);
    }

    return {
        name,
        id,
        start,
        end,
        lines
    };
}

/**
 * Given a Gatling simulation class name, extracts the Jira issue reference if the class name ends with '_PROJECT_ID',
 * where 'PROJECT' is the Jira project and ID is the unique ID of the Jira Xray test issue, where 'PROJECT-ID' is the
 * unique Jira key for the Jira Xray test issue
 *
 * Returns an object with the following properties:
 *
 *      project     Jira project
 *      id          ID of Jira issue within project
 *      key         Jira key (created using `${project}-${id}`)
 *
 * @param {String} value Gatling simulation class name
 * @returns {Object} Jira issue details, if class name has required format; otherwise undefined is returned.
 */
function getJiraIssue(value) {
    const regex = /_([A-Z][A-Z0-9]+)_(\d+)$/;
    const matches = value.match(regex);
    if (!matches) {
        return undefined;
    }
    const project = matches[1];
    const id = parseNumeric(matches[2]);
    return {
        project,
        id,
        key: project + '-' + id
    };
}

/**
 * Embeds data within a Cucumber JSON report step, allowing it to be easily viewed within Jira Xray test issue execution results.
 *
 * Embedded data is Base64 encoded
 *
 * @param {Object} step Cucumber JSON report step details
 * @param {String} data Data string to be embedded
 * @param {String} mimeType Mime type of data (text/plain or application/json for example)
 */
function embed(step, data, mimeType) {
    if (!step.embeddings) {
        // Ensure that embeddings is defined, which is an array
        step.embeddings = [];
    }
    step.embeddings.push({
        data: Buffer.from(data).toString(BASE64),
        mime_type: mimeType
    });
}

/**
 * For a given simulation, the following inputs are used to generate a Cucumber JSON report which can be uploaded into Jira.
 *
 *          Simulation class name, from which Jira Xray test issue reference is retrieved
 *          Gatling log information
 *          Performance log information (as stored within performance.log file)
 *          Assertion information (as stored within js/assertions.json, and used to determine whether simulation passed/failed
 *
 * @param {[String]} errors Array of errors, encountered so far
 * @param {String} outputFolder Folder into which Cucumber JSON file is to be created
 * @param {Object} performanceDetails Performance log details for the simulation
 * @param {Object} assertions Assertion details for the simulation
 * @param {Object} logDetails Gatling log information for this simulation
 * @param {Object} jiraIssues Jira issues previously used (keyed on Jira issue key) - should only be referenced the once
 * @param {Object} cucumberJsonReports Cucumber JSON reports generated
 */
function createCucumberReport(errors, outputFolder, performanceDetails, assertions, logDetails, jiraIssues, cucumberJsonReports) {

    const timeTaken = (performanceDetails.start && performanceDetails.end) ? (performanceDetails.end - performanceDetails.start) : 0;

    const jiraIssue = getJiraIssue(performanceDetails.name);
    if (!jiraIssue) {
        recordError(errors, `Simulation name '${performanceDetails.name}' does not contain Jira ticket reference`);
    } else if (!validJiraProjects.includes(jiraIssue.project)) {
        recordError(errors, `Simulation name '${performanceDetails.name}' references Jira ticket '${jiraIssue.key}' but project '${jiraIssue.project}' is not a valid Jira project (${JSON.stringify(validJiraProjects)})`);
    } else {
        if (jiraIssues[jiraIssue.key]) {
            recordError(errors, `Simulation name '${performanceDetails.name}' references Jira ticket '${jiraIssue.key}' which has also been referenced by ${jiraIssues[jiraIssue.key]}`);
        } else {
            jiraIssues[jiraIssue.key] = performanceDetails.name;
        }
    }

    // NOTE: Do not directly manipulate template - instead take a deep clone so that each cucumber report created is separate to each other
    const json = _.cloneDeep(template);

    const feature = json[0];
    const scenario = feature.elements[0];
    const step1 = scenario.steps[0];
    const step2 = scenario.steps[1];
    let tag;

    feature.name = `Gatling simulation '${performanceDetails.name}'`;
    feature.description = feature.name;
    feature.id = performanceDetails.id;
    feature.url = performanceDetails.name;

    scenario.name = feature.description;

    if (jiraIssue) {
        tag = `@${jiraIssue.key}`;
        scenario.tags[0].name = tag;
    } else {
        tag = TAG_NONE;
        delete scenario.tags;
    }

    step1.name = feature.name;
    step1.result.duration = timeTaken * DURATION_FACTOR;

    // Embed performance log details
    embed(step1, performanceDetails.lines.join('\n'), MIME_TYPE_TEXT);

    if (logDetails) {
        // Embed simulation log details
        embed(step1, logDetails.lines.join('\n'), MIME_TYPE_TEXT);
    }

    let passed;
    let message;
    let passedCount = 0;
    let failedCount = 0;

    if (assertions.assertions.length === 0) {
        passed = false;
        failedCount ++;
        message = 'FAIL: No assertions present!';
    } else {
        passed = true;  // Assume true - unless one or more steps fail
        message = '';
        assertions.assertions.forEach(assertion => {
            let status;
            passed = passed && assertion.result;
            if (assertion.result) {
                passedCount ++;
                status = 'PASS';
            } else {
                failedCount ++;
                status = 'FAIL';
            }
            if (message) {
                message += '\n';
            }
            message += `${status}: ${assertion.message}`;
            if (assertion.actualValue !== undefined) {
                message += ` (actual value: ${JSON.stringify(assertion.actualValue)})`;
            }
        });
    }

    step2.name = `Assertions (passed: ${[passedCount]} failed: ${failedCount})`;
    step2.result.status = passed ? 'passed' : 'failed';
    if (!passed) {
        // Error message is displayed automatically, no clicks required, when the results are uploaded into Jira Xray.
        step2.result.error_message = message;
    }
    step2.doc_string = {
        content_type: '',
        value: message,
        line: step2.line
    };

    // Embed message, as it will not appear if the step is successful within Jira test execution details.
    embed(step2, message, MIME_TYPE_TEXT);

    // Embed assertions JSON data
    embed(step2, JSON.stringify(assertions, null, TAB_SIZE), MIME_TYPE_JSON);

    const outputFileName = path.join(outputFolder, performanceDetails.id + '.json');

    if (fs.existsSync(outputFileName)) {
        recordError(errors, `Unable to create Cucumber JSON report file '${outputFileName}' for '${performanceDetails.name}' as file already exists`);
    } else {
        fs.writeFileSync(outputFileName, JSON.stringify(json, null, TAB_SIZE));

        console.log(`INFO: Created cucumber JSON report '${outputFileName}' - tag: ${tag} passed: ${passed}`);

        cucumberJsonReports[outputFileName] = {
            fileName: outputFileName,
            passed,
            tag
        };
    }
}

/**
 * Given the following inputs:
 *
 *      Gatling log output (optional)
 *      Gatling results folder (default target/gatling)
 *
 * It will process, for each simulation, the simulation log file (simulation.log) and the assertions file (js/assertions.json),
 * and create a Cucumber JSON report which can be uploaded into Jira Xray
 *
 * @param {Object} options Options for generating Cucumber JSON report files.
 */
function generateCucumberJson(options) {
    options = options || {};

    options.gatlingResultsFolder = options.gatlingResultsFolder || DEFAULT_GATLING_RESULTS_FOLDER;
    options.outputFolder = options.outputFolder || DEFAULT_OUTPUT_FOLDER;

    if (utils.isDirectory(options.outputFolder)) {
        if (!options.overwrite) {
            throw new Error(`Output folder '${options.outputFolder}' directory already exists - please remove, specify a different folder name or use -overwrite`);
        }
        utils.rmdir(options.outputFolder);
    }

    const logOutput = options.gatlingResultsFile ? loadResultsFile(options.gatlingResultsFile) : undefined;

    const folders = utils.getFolders(options.gatlingResultsFolder, false);

    const errors = [];
    const cucumberJsonReports = {}; // key: fileName value: { fileName, tag, passed }

    if (folders.length === 0) {
        recordError(errors, `Gatling results folder '${options.gatlingResultsFolder}' contains no child folders`);
    } else {
        console.log();
        // Create output folder
        utils.mkdir(options.outputFolder);

        // Keep track of Jira test issues referenced - key: Jira-test-issue value: simulation-class-name
        const jiraIssues = {};

        folders.forEach(folder => {

            console.log();

            const simulationFileName = path.join(folder, 'simulation.log');
            const assertionsFileName = path.join(folder, 'js', 'assertions.json');
            if (!fs.existsSync(simulationFileName)) {
                recordError(errors, `Simulation log file '${simulationFileName}' does not exist`);
                return;
            }
            if (!fs.existsSync(assertionsFileName)) {
                recordError(errors, `Assertions JSON file  '${assertionsFileName}' does not exist`);
                return;
            }

            const performanceDetails = loadPerformanceDetails(errors, simulationFileName);
            console.log(`Loading assertions file '${assertionsFileName}'`);
            const assertions = utils.loadJson(assertionsFileName);

            if (performanceDetails.name !== assertions.simulation) {
                recordError(errors, `Simulation name '${performanceDetails.name}' within '${simulationFileName}' does not match '${assertions.simulation}' within '${assertionsFileName}'`);
                return;
            }

            const logDetails = logOutput ? logOutput[performanceDetails.name] : undefined;
            if (logOutput && !logDetails) {
                recordError(errors, `Log details for '${performanceDetails.name}' do not exist`);
            }

            createCucumberReport(errors,
                options.outputFolder,
                performanceDetails,
                assertions,
                logDetails,
                jiraIssues,
                cucumberJsonReports
            );
        });
    }

    console.log();
    const keys = Object.keys(cucumberJsonReports);
    console.log(`INFO: The following Cucumber JSON reports were generated (${keys.length}):`);
    console.log();
    let passed = 0;
    let failed = 0;
    let noTag = 0;
    keys.sort().forEach(key => {
        const info = cucumberJsonReports[key];
        console.log(`    ${info.fileName} Tag: ${info.tag} Passed: ${info.passed}`);
        if (info.passed) {
            passed ++;
        } else {
            failed ++;
        }
        if (info.tag === TAG_NONE) {
            noTag ++;
        }
    });
    console.log();
    let status = `INFO: Passed ${passed} Failed: ${failed} Errors: ${errors.length}`;
    if (noTag > 0) {
        status += ` No tag defined: ${noTag}`;
    }
    console.log(status);

    const results = {
        cucumberJsonReports,
        errors
    };

    if (errors.length === 0) {
        results.successful = true;
    } else {
        results.successful = false;
        console.log();
        console.log(`FAIL: The following errors were detected (${errors.length}):\n\n    ` + errors.join('\n    '));
    }

    return results;
}

module.exports = {
    DEFAULT_GATLING_RESULTS_FOLDER,
    generateCucumberJson,
    VERSION
};
