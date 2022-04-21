#!/usr/bin/env node
'use strict';

const yargs = require('yargs');
const generate = require('../lib/generate');

var args = yargs.help('help')
    .showHelpOnFail(false, 'Specify --help for available options')
    .demand(0)
    .strict()
    .usage('\n' + 'gatling-generate-cucumber-json')
    .version(generate.VERSION)
    .describe({
        'gatling-results-file': 'Gatling results file',
        'gatling-results-folder': 'Gatling results folder',
        'output-folder': 'Folder to create Cucumber JSON files'
    })
    .boolean([
        'overwrite'
    ])
    .string([
        'gatling-results-file',
        'gatling-results-folder',
        'output-folder'
    ])
    .default('gatling-results-file')
    .default('gatling-results-folder', generate.DEFAULT_GATLING_RESULTS_FOLDER)
    .default('overwrite', false)
    .wrap(yargs.terminalWidth())
    .argv;

if (args._.length !== 0) {
    throw new Error('gatling-generate-cucumber-json: see --help for details');
}

const results = generate.generateCucumberJson({
    gatlingResultsFile: args.gatlingResultsFile,
    gatlingResultsFolder: args.gatlingResultsFolder,
    outputFolder: args.outputFolder,
    overwrite: args.overwrite
});

if (!results.successful) {
    // Ensure exit code is reflective of the failure to generate the Cucumber JSON file(s).
    process.exit(1);
}
