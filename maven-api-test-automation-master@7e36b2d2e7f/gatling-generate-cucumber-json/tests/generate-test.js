'use strict';

const chai = require('chai');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const utils = require('../lib/utils');
const generate = require('../lib/generate');

/**
 * Calculates hash of file based on its contents, which is returned as a hex string
 *
 * @param {string} filePath Path to file
 * @returns {string} File hash as a hex string
 */
function calcHash(filePath) {
    const data = fs.readFileSync(filePath);
    return crypto.createHash('sha1').update(data).digest('hex');
}

/**
 * Fixup a file path, replacing backslashes with forward slashes, as when using Git Bash on Windows, it can't handle backslashes
 *
 * @param {string} filePath
 */
function fixup(filePath) {
    return filePath.replace(/\\/g, '/');
}

/**
 * Compares two sets of files to make sure they are the same
 *
 * File hashes are used to determine same-ness.
 *
 * @param {string} root1 Root of first list of files
 * @param {[string]} files1 List of files within first root
 * @param {string} root2 Root of second list of files
 * @param {[string]} files2  List of files within second root
 */
function checkSameFileContent(root1, files1, root2, files2) {

    chai.assert.notEqual(root1, root2, 'Root folders must be different');
    chai.assert.equal(files1.length, files2.length, `Same number of files in '${root1}' and '${root2}'`);

    let count = 0;

    for (let i = 0; i < Math.max(files1.length, files2.length); i++) {
        chai.assert.equal(files1[i], files2[i], `File # ${i}`);

        const fileName1 = path.join(root1, files1[i]);
        const fileName2 = path.join(root2, files2[i]);

        const hash1 = calcHash(fileName1);
        const hash2 = calcHash(fileName2);

        // NOTE: Do not fail on first, report all differences and then fail

        if (hash1 !== hash2) {
            console.error(`FAIL: Hashes different:\n\t${hash1} ${fixup(fileName1)}\n\t${hash2} ${fixup(fileName2)}`);
            count ++;
        } else {
            console.log(`INFO: Hashes same:\n\t${hash1} ${fixup(fileName1)}\n\t${hash2} ${fixup(fileName2)}`);
        }
    }

    // No differences should be present
    chai.assert.equal(count, 0, 'Number of hash mismatches');
}

function addCucumberJsonReport(reports, fileName, tag, passed) {
    reports[fileName] = {
        fileName,
        tag,
        passed
    };
}

describe('Gatling Cucumber JSON Report Verification', function() {

    it('Data set #1', async () => {

        const rootFolder = './tests/data';

        const testFolder = path.join(rootFolder, 'test1');
        const resultsFolder = path.join(rootFolder, 'results', 'test1');

        if (utils.isDirectory(resultsFolder)) {
            utils.rmdir(resultsFolder);
        }

        const options = {
            gatlingResultsFile: path.join(testFolder, 'output.txt'),
            gatlingResultsFolder: path.join(testFolder, 'gatling'),
            outputFolder: resultsFolder
        };

        chai.assert.equal(utils.isFile(options.gatlingResultsFile), true, `Results file '${options.gatlingResultsFile}' exists`);
        chai.assert.equal(utils.isDirectory(options.gatlingResultsFolder), true, `Results folder '${options.gatlingResultsFolder}' exists`);
        chai.assert.equal(utils.isDirectory(options.outputFolder), false, `Output folder '${options.outputFolder}' does not exist`);

        const results = generate.generateCucumberJson(options);
        const expected = {
            successful: true,
            cucumberJsonReports: {},
            errors: []
        };

        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'examplesscenario-example-10.json'),  '@EXAMPLE-10', false);
        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'photosgetscenario-example-11.json'), '@EXAMPLE-11', true);
        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'postsgetscenario-example-12.json'),  '@EXAMPLE-12', true);
        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'postspostscenario-example-13.json'), '@EXAMPLE-13', true);
        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'todos403scenario-example-14.json'),  '@EXAMPLE-14', true);
        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'userspostscenario-example-15.json'), '@EXAMPLE-15', true);

        chai.assert.deepEqual(results, expected, 'Generation results');

        chai.assert.equal(utils.isDirectory(options.outputFolder), true, `Output folder '${options.outputFolder}' exists`);

        const expectedOutputFolder = path.join(testFolder, 'expected-results');
        const expectedFiles = utils.getFiles(expectedOutputFolder).sort();
        const actualFiles = utils.getFiles(options.outputFolder).sort();

        chai.assert.deepEqual(actualFiles, expectedFiles, 'Result files');
        checkSameFileContent(expectedOutputFolder, expectedFiles, options.outputFolder, actualFiles);
    });

    it('Data set #2', async () => {

        const rootFolder = './tests/data';

        const testFolder = path.join(rootFolder, 'test2');
        const resultsFolder = path.join(rootFolder, 'results', 'test2');

        if (utils.isDirectory(resultsFolder)) {
            utils.rmdir(resultsFolder);
        }

        const options = {
            gatlingResultsFile: path.join(testFolder, 'gatling-output.txt'),
            gatlingResultsFolder: path.join(testFolder, 'gatling-results'),
            outputFolder: resultsFolder
        };

        chai.assert.equal(utils.isFile(options.gatlingResultsFile), true, `Results file '${options.gatlingResultsFile}' exists`);
        chai.assert.equal(utils.isDirectory(options.gatlingResultsFolder), true, `Results folder '${options.gatlingResultsFolder}' exists`);
        chai.assert.equal(utils.isDirectory(options.outputFolder), false, `Output folder '${options.outputFolder}' does not exist`);

        const results = generate.generateCucumberJson(options);
        const expected = {
            successful: false,
            cucumberJsonReports: {},
            errors:  [
                'Simulation name \'performance.ExamplesScenario\' does not contain Jira ticket reference',
                'Simulation name \'performance.PhotosGetScenario\' does not contain Jira ticket reference',
                'Simulation name \'performance.PostsGetScenario\' does not contain Jira ticket reference',
                'Simulation name \'performance.PostsPostScenario\' does not contain Jira ticket reference',
                'Simulation name \'performance.Todos403Scenario\' does not contain Jira ticket reference',
                'Simulation name \'performance.UsersPostScenario\' does not contain Jira ticket reference'
            ]
        };

        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'examplesscenario.json'),  '<none>', false);
        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'photosgetscenario.json'), '<none>', true);
        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'postsgetscenario.json'),  '<none>', true);
        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'postspostscenario.json'), '<none>', true);
        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'todos403scenario.json'),  '<none>', false);
        addCucumberJsonReport(expected.cucumberJsonReports, path.join(options.outputFolder, 'userspostscenario.json'), '<none>', true);

        chai.assert.deepEqual(results, expected, 'Generation results');

        chai.assert.equal(utils.isDirectory(options.outputFolder), true, `Output folder '${options.outputFolder}' exists`);

        const expectedOutputFolder = path.join(testFolder, 'expected-results');
        const expectedFiles = utils.getFiles(expectedOutputFolder).sort();
        const actualFiles = utils.getFiles(options.outputFolder).sort();

        chai.assert.deepEqual(actualFiles, expectedFiles, 'Result files');
        checkSameFileContent(expectedOutputFolder, expectedFiles, options.outputFolder, actualFiles);
    });
});
