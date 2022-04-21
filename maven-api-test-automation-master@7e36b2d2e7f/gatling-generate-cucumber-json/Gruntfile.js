'use strict';
const _ = require('lodash');
const matchdep = require('matchdep');

module.exports = function(grunt) {

    // load all grunt tasks
    matchdep.filterDev('grunt-*').forEach(grunt.loadNpmTasks);

    const codeFiles = ['**/*.js', '!node_modules/**'];

    /**
     * For JSON files, we will automatically reformat them; however, this will not be done for the files within tests/data
     * as we need these to remain as is.
     *
     * Reformatting JSON files will ensure a blank line is at the end of the file, which will cause the test comparing
     * the results to the expected results to fail.
     */
    const jsonFiles = ['**/*.json', '!node_modules/**', '!tests/data/**'];
    const jsonFilesReadOnly = ['tests/data/**/*.json'];

    const JSON_INDENT = 4;

    /**
     * Gets a grunt option value, ensuring false and zero are returned as strings
     *
     * @param {string} option Grunt option name
     * @returns {string} Value, as a string - important for false & zero.
     */
    function getGruntOption(option) {
        var value = grunt.option(option);
        if (_.isBoolean(value) || _.isNumber(value)) {
            value = value.toString();
        }
        return value;
    }

    /**
     * Create environment variables for tests
     * @param {boolean} [verbose] Whether to enable verbose logging
     */
    function getEnv() {
        return {
            CONFIG_JSON_INDENT: JSON_INDENT.toString()
        };
    }

    /**
     * Create mocha options for tests
     *
     * @param {boolean} [testFailureIgnore] Whether to ignore test failures
     * @param {object} [merge] Additional options to merge into standard options
     */
    function getOptions(testFailureIgnore, merge) {
        testFailureIgnore = testFailureIgnore || false;
        const options = {
            files: [getGruntOption('tests') || 'tests/**/*.js'],
            grep: getGruntOption('filter') || getGruntOption('grep'),
            timeout: [getGruntOption('timeout') || 15000],
            'no-timeouts': [getGruntOption('no-timeouts') || false],
            force: testFailureIgnore,    // Force grunt to exit with exit code 0 even if there are test failures present
            env: getEnv()
        };

        if (_.isPlainObject(merge)) {
            _.merge(options, merge);
        }

        return options;
    }

    // Project configuration.
    grunt.initConfig({
        mochacli: {
            options: {
                reporter: 'spec'
            },
            tests: {
                options: getOptions()
            },
            tests_jenkins: {
                options: getOptions(true, {
                    reporter: 'mocha-jenkins-reporter',
                    'reporter-options': {
                        'junit_report_path': getGruntOption('test-results-output') || './test-results.xml'
                    }
                })
            }
        },
        eslint: {
            default: {
                src: codeFiles,
                options: {
                    fix: true,
                    quiet: true
                }
            },
            verifyOnly: {
                src: codeFiles,
                options: {
                    fix: false
                }
            }
        },
        jsonlint: {
            default: {
                src: jsonFiles,
                options: {
                    format: true,
                    indent: JSON_INDENT
                }
            },
            readOnly: {
                src: jsonFilesReadOnly,
                options: {
                    format: false
                }
            },
            verifyOnly: {
                src: jsonFiles,
                options: {
                    format: false
                }
            }
        }
    });

    grunt.registerTask('default', 'tests');
    grunt.registerTask('check', ['eslint:default', 'jsonlint:default', 'jsonlint:readOnly']);
    grunt.registerTask('check-verify-only', ['eslint:verifyOnly', 'jsonlint:verifyOnly', 'jsonlint:readOnly']);
    grunt.registerTask('tests', ['check', 'mochacli:tests']);
    grunt.registerTask('tests-jenkins', ['check-verify-only', 'mochacli:tests_jenkins']);
};
