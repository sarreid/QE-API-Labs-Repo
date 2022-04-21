# Gatling - Generate Cucumber JSON

## Gatling

Gatling is an option source project which is used for performance automation - <https://github.com/gatling/gatling>

## Gatling Simulations and Jira Xray Test Association

There is no way to tag Gatling tests in the same manner as that used for Karate API/UI automation tests.

In order to associate a Gatling simulation class with a Jira Xray test issue, you need to embed the Jira issue key at the end of the simulation class name.  For example:

```scala
class UsersPostScenario_EXAMPLE_1234 extends Simulation {
    :
}
```

This associates Jira Xray test issue EXAMPLE-1234.

See [UsersPostScenario.scala](../src/test/performance/api-users/UsersPostScenario.scala) for an example within the template folder.

## Support Scripts

### Generate Cucumber JSON Reports

The script `gatling-generate-cucumber-json.sh` generates Cucumber JSON reports which can be uploaded to Jira Xray test issues as execution results.

Use `--help` to display the script's usage:

```text
$ ./gatling-generate-cucumber-json.sh --help

 gatling-generate-cucumber-json

Options:
  --help                    Show help  [boolean]
  --version                 Show version number  [boolean]
  --gatling-results-file    Gatling results file  [string]
  --gatling-results-folder  Gatling results folder  [string] [default: "./target/gatling"]
  --output-folder           Folder to create Cucumber JSON files  [string]
  --overwrite  [boolean] [default: false]
```

## Verifying and Testing the Code

The scripts for decoding and encoding Hoverfly simulation files, are written using:

- Node and Javascript
- Grunt for running eslint (JavaScript linter) and jsonlint (JSON validator and formatter).
- Mocha for unit tests

To verify the code and run the tests:

```bash
./run-tests.sh
```

The `run-tests.sh` script will execute the following commands:

```bash
# 'npm ci' is only executed if the node_modules folder does not exist
npm ci
npm run tests
```

This will show output similar to:

```text
> gatling-generate-cucumber-json@1.0.0 tests ...\api-test-automation-template\gatling-generate-cucumber-json
> grunt tests

>> Local Npm module "grunt-cli" not found. Is it installed?

Running "eslint:default" (eslint) task

Running "jsonlint:default" (jsonlint) task
>> 4 files lint free.

Running "jsonlint:readOnly" (jsonlint) task
>> 36 files lint free.

Running "mochacli:tests" (mochacli) task


  Gatling Cucumber JSON Report Verification
Deleting folder 'tests\data\results\test1'
Processing Gatling results file 'tests\data\test1\output.txt'
Found start of simulation 'performance.ExamplesScenario_EXAMPLE_10' at line number 36
Found start of simulation 'performance.PhotosGetScenario_EXAMPLE_11' at line number 102
Found start of simulation 'performance.PostsGetScenario_EXAMPLE_12' at line number 168
Found start of simulation 'performance.PostsPostScenario_EXAMPLE_13' at line number 234
Found start of simulation 'performance.Todos403Scenario_EXAMPLE_14' at line number 300
Found start of simulation 'performance.UsersPostScenario_EXAMPLE_15' at line number 366
Gatling results file 'tests\data\test1\output.txt' contained information for 6 simulations

Creating folder 'tests\data\results\test1'

Processing performance log file 'tests\data\test1\gatling\examplesscenario-example-10-20210310041632618\simulation.log'
Loading assertions file 'tests\data\test1\gatling\examplesscenario-example-10-20210310041632618\js\assertions.json'
INFO: Created cucumber JSON report 'tests\data\results\test1\examplesscenario-example-10.json' - tag: @EXAMPLE-10 passed: false

Processing performance log file 'tests\data\test1\gatling\photosgetscenario-example-11-20210310041646867\simulation.log'
Loading assertions file 'tests\data\test1\gatling\photosgetscenario-example-11-20210310041646867\js\assertions.json'
INFO: Created cucumber JSON report 'tests\data\results\test1\photosgetscenario-example-11.json' - tag: @EXAMPLE-11 passed: true

Processing performance log file 'tests\data\test1\gatling\postsgetscenario-example-12-20210310041701424\simulation.log'
Loading assertions file 'tests\data\test1\gatling\postsgetscenario-example-12-20210310041701424\js\assertions.json'
INFO: Created cucumber JSON report 'tests\data\results\test1\postsgetscenario-example-12.json' - tag: @EXAMPLE-12 passed: true

Processing performance log file 'tests\data\test1\gatling\postspostscenario-example-13-20210310041716021\simulation.log'
Loading assertions file 'tests\data\test1\gatling\postspostscenario-example-13-20210310041716021\js\assertions.json'
INFO: Created cucumber JSON report 'tests\data\results\test1\postspostscenario-example-13.json' - tag: @EXAMPLE-13 passed: true

Processing performance log file 'tests\data\test1\gatling\todos403scenario-example-14-20210310041731639\simulation.log'
Loading assertions file 'tests\data\test1\gatling\todos403scenario-example-14-20210310041731639\js\assertions.json'
INFO: Created cucumber JSON report 'tests\data\results\test1\todos403scenario-example-14.json' - tag: @EXAMPLE-14 passed: true

Processing performance log file 'tests\data\test1\gatling\userspostscenario-example-15-20210310041746644\simulation.log'
Loading assertions file 'tests\data\test1\gatling\userspostscenario-example-15-20210310041746644\js\assertions.json'
INFO: Created cucumber JSON report 'tests\data\results\test1\userspostscenario-example-15.json' - tag: @EXAMPLE-15 passed: true

INFO: The following Cucumber JSON reports were generated (6):

    tests\data\results\test1\examplesscenario-example-10.json Tag: @EXAMPLE-10 Passed: false
    tests\data\results\test1\photosgetscenario-example-11.json Tag: @EXAMPLE-11 Passed: true
    tests\data\results\test1\postsgetscenario-example-12.json Tag: @EXAMPLE-12 Passed: true
    tests\data\results\test1\postspostscenario-example-13.json Tag: @EXAMPLE-13 Passed: true
    tests\data\results\test1\todos403scenario-example-14.json Tag: @EXAMPLE-14 Passed: true
    tests\data\results\test1\userspostscenario-example-15.json Tag: @EXAMPLE-15 Passed: true

INFO: No errors detected
INFO: Hashes same:
        24920d268c432fc5416ee1d96b47a2c675423775 tests/data/test1/expected-results/examplesscenario-example-10.json
        24920d268c432fc5416ee1d96b47a2c675423775 tests/data/results/test1/examplesscenario-example-10.json
INFO: Hashes same:
        2618bd485d703abd857f56bde61ae1308c354abe tests/data/test1/expected-results/photosgetscenario-example-11.json
        2618bd485d703abd857f56bde61ae1308c354abe tests/data/results/test1/photosgetscenario-example-11.json
INFO: Hashes same:
        989a39043f7d5224d4b0d266cd259d949d79124e tests/data/test1/expected-results/postsgetscenario-example-12.json
        989a39043f7d5224d4b0d266cd259d949d79124e tests/data/results/test1/postsgetscenario-example-12.json
INFO: Hashes same:
        95e1bb71e51a045dbf3115a2b0d3172f1d47fee4 tests/data/test1/expected-results/postspostscenario-example-13.json
        95e1bb71e51a045dbf3115a2b0d3172f1d47fee4 tests/data/results/test1/postspostscenario-example-13.json
INFO: Hashes same:
        843aa00bef76944b0bceae72e680a4452f7c9540 tests/data/test1/expected-results/todos403scenario-example-14.json
        843aa00bef76944b0bceae72e680a4452f7c9540 tests/data/results/test1/todos403scenario-example-14.json
INFO: Hashes same:
        14c34369a777cf39c0220d76ff39b1537fa0f2b5 tests/data/test1/expected-results/userspostscenario-example-15.json
        14c34369a777cf39c0220d76ff39b1537fa0f2b5 tests/data/results/test1/userspostscenario-example-15.json
    √ Data set #1 (57ms)
Deleting folder 'tests\data\results\test2'
Processing Gatling results file 'tests\data\test2\gatling-output.txt'
Found start of simulation 'performance.ExamplesScenario' at line number 36
Found start of simulation 'performance.PhotosGetScenario' at line number 102
Found start of simulation 'performance.PostsGetScenario' at line number 168
Found start of simulation 'performance.PostsPostScenario' at line number 234
Found start of simulation 'performance.Todos403Scenario' at line number 300
Found start of simulation 'performance.UsersPostScenario' at line number 366
Gatling results file 'tests\data\test2\gatling-output.txt' contained information for 6 simulations

Creating folder 'tests\data\results\test2'

Processing performance log file 'tests\data\test2\gatling-results\examplesscenario-20210309220533730\simulation.log'
Loading assertions file 'tests\data\test2\gatling-results\examplesscenario-20210309220533730\js\assertions.json'
FAIL: Simulation name 'performance.ExamplesScenario' does not contain Jira ticket reference
INFO: Created cucumber JSON report 'tests\data\results\test2\examplesscenario.json' - tag: <none> passed: false

Processing performance log file 'tests\data\test2\gatling-results\photosgetscenario-20210309220548753\simulation.log'
Loading assertions file 'tests\data\test2\gatling-results\photosgetscenario-20210309220548753\js\assertions.json'
FAIL: Simulation name 'performance.PhotosGetScenario' does not contain Jira ticket reference
INFO: Created cucumber JSON report 'tests\data\results\test2\photosgetscenario.json' - tag: <none> passed: true

Processing performance log file 'tests\data\test2\gatling-results\postsgetscenario-20210309220603936\simulation.log'
Loading assertions file 'tests\data\test2\gatling-results\postsgetscenario-20210309220603936\js\assertions.json'
FAIL: Simulation name 'performance.PostsGetScenario' does not contain Jira ticket reference
INFO: Created cucumber JSON report 'tests\data\results\test2\postsgetscenario.json' - tag: <none> passed: true

Processing performance log file 'tests\data\test2\gatling-results\postspostscenario-20210309220618841\simulation.log'
Loading assertions file 'tests\data\test2\gatling-results\postspostscenario-20210309220618841\js\assertions.json'
FAIL: Simulation name 'performance.PostsPostScenario' does not contain Jira ticket reference
INFO: Created cucumber JSON report 'tests\data\results\test2\postspostscenario.json' - tag: <none> passed: true

Processing performance log file 'tests\data\test2\gatling-results\todos403scenario-20210309220634149\simulation.log'
Loading assertions file 'tests\data\test2\gatling-results\todos403scenario-20210309220634149\js\assertions.json'
FAIL: Simulation name 'performance.Todos403Scenario' does not contain Jira ticket reference
INFO: Created cucumber JSON report 'tests\data\results\test2\todos403scenario.json' - tag: <none> passed: false

Processing performance log file 'tests\data\test2\gatling-results\userspostscenario-20210309220649203\simulation.log'
Loading assertions file 'tests\data\test2\gatling-results\userspostscenario-20210309220649203\js\assertions.json'
FAIL: Simulation name 'performance.UsersPostScenario' does not contain Jira ticket reference
INFO: Created cucumber JSON report 'tests\data\results\test2\userspostscenario.json' - tag: <none> passed: true

INFO: The following Cucumber JSON reports were generated (6):

    tests\data\results\test2\examplesscenario.json Tag: <none> Passed: false
    tests\data\results\test2\photosgetscenario.json Tag: <none> Passed: true
    tests\data\results\test2\postsgetscenario.json Tag: <none> Passed: true
    tests\data\results\test2\postspostscenario.json Tag: <none> Passed: true
    tests\data\results\test2\todos403scenario.json Tag: <none> Passed: false
    tests\data\results\test2\userspostscenario.json Tag: <none> Passed: true

FAIL: The following errors were detected (6):

    Simulation name 'performance.ExamplesScenario' does not contain Jira ticket reference
    Simulation name 'performance.PhotosGetScenario' does not contain Jira ticket reference
    Simulation name 'performance.PostsGetScenario' does not contain Jira ticket reference
    Simulation name 'performance.PostsPostScenario' does not contain Jira ticket reference
    Simulation name 'performance.Todos403Scenario' does not contain Jira ticket reference
    Simulation name 'performance.UsersPostScenario' does not contain Jira ticket reference
INFO: Hashes same:
        62e919e121e1534c151fabe64e60bf311548041a tests/data/test2/expected-results/examplesscenario.json
        62e919e121e1534c151fabe64e60bf311548041a tests/data/results/test2/examplesscenario.json
INFO: Hashes same:
        199dd064098ef09b979eb2aadbfb61c72f95980a tests/data/test2/expected-results/photosgetscenario.json
        199dd064098ef09b979eb2aadbfb61c72f95980a tests/data/results/test2/photosgetscenario.json
INFO: Hashes same:
        774d0f353769d826b3e9db8e7b15d58151a7c251 tests/data/test2/expected-results/postsgetscenario.json
        774d0f353769d826b3e9db8e7b15d58151a7c251 tests/data/results/test2/postsgetscenario.json
INFO: Hashes same:
        6f771f590aa04cd11f105f15b72478bfd241b85d tests/data/test2/expected-results/postspostscenario.json
        6f771f590aa04cd11f105f15b72478bfd241b85d tests/data/results/test2/postspostscenario.json
INFO: Hashes same:
        5e47d6ac8921177e26b6053fa5b4e4aafffd24a6 tests/data/test2/expected-results/todos403scenario.json
        5e47d6ac8921177e26b6053fa5b4e4aafffd24a6 tests/data/results/test2/todos403scenario.json
INFO: Hashes same:
        f1cda7724743925407f68fe3c57a1f410cd83196 tests/data/test2/expected-results/userspostscenario.json
        f1cda7724743925407f68fe3c57a1f410cd83196 tests/data/results/test2/userspostscenario.json
    √ Data set #2 (46ms)


  2 passing (112ms)
```

## Verifying and Testing Code on Jenkins

To verify and test the code on Jenkins, within a branch build pipeline:

```bash
npm ci
npm run tests-jenkins
```

This will generate the Junit results files `test-results.xml` which can be processed by Jenkins to pass or fail the build.
