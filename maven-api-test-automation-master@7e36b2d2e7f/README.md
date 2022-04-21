# API Test Automation Framework

## Overview

The API test automation framework uses the following open source projects:

- Karate for API/UI automation - <https://github.com/intuit/karate>
- Gatling for performance automation - <https://github.com/gatling/gatling>

The examples included within the framework test the `posts`, `users`, `todos` and `photos` APIs provided by:

- <https://jsonplaceholder.typicode.com/>
- <https://via.placeholder.com/>

See <https://jsonplaceholder.typicode.com/guide/> and <https://placeholder.com/> for details of the APIs provided.

## Type of Testing

Karate and Gatling integration is achieved using the following Maven plugins:

- Surefire <https://maven.apache.org/surefire/maven-surefire-plugin/> - this plugin runs Junit tests

    To view configuration items available, run `mvn surefire:help --define detail=true --define goal=test`.

- Gatling <https://gatling.io/docs/current/extensions/maven_plugin/> - this plugin runs Gatling simulations

    To view configuration items available, run `mvn gatling:help --define detail=true --define goal=test`.

> Karate integration has been implemented by running a single Junit test, which is responsible for launching Karate.  See  [TagBasedApiRunner.java](./src/test/java/runner/TagBasedApiRunner.java).

There are three categories of tests within this project:

- Unit tests.  A collection of Junit tests to test the Java related code
- Karate tests.  A collection of Karate feature files to test API/UI being developed
- Gatling tests.  A collection of Gatling simulation tests which allow performance characteristics of APIs to be validated

Each of these are run separately.

- Unit tests

    ```bash
    mvn clean test-compile 'surefire:test' --activate-profiles unit-tests
    ```

- Karate tests

    ``` bash
    mvn clean test-compile 'surefire:test' --activate-profiles karate-tests --define karate.env=dev
    ```

- Gatling tests

    ``` bash
    mvn clean test-compile 'gatling:test' --define karate.env=dev --define logback.configurationFile=logback-no-console-test.xml

    ```

To simplify things, run-tests.sh has a test mode:

- Unit tests

    ```bash
    ./run-tests.sh --test-mode unit
    ```

- Karate tests

    ``` bash
    ./run-tests.sh --test-mode karate
    ```

- Gatling tests

    ``` bash
    ./run-tests.sh --test-mode gatling
    ```

## Configuration and Environments

Karate provides per scenario configuration using [src/test/resources/karate-config.js](src/test/resources/karate-config.js) - see <https://github.com/intuit/karate#configuration> for more details.

In addition, Karate provides environment specific configuration, which provides ability to override the main configuration values, provided by `karate-config.js`.

See <https://github.com/intuit/karate#environment-specific-config> for more details.

Within the framework the following environment configurations are available.

| Environment | Configuration File                                                                   | Description                                        |
|-------------|--------------------------------------------------------------------------------------|----------------------------------------------------|
| DEV         | [src/test/resources/karate-config-dev.js](src/test/resources/karate-config-dev.js)   | Development environment - uncontrolled deployments |
| TEST        | [src/test/resources/karate-config-test.js](src/test/resources/karate-config-test.js) | Formal test environment - controlled deployments   |

> **IMPORTANT:_** In order to use environment specific configuration, the karate specific Java system property `karate.env` **_MUST_** be defined.

To run the tests against the `DEV` environment:

```bash
mvn clean test-compile surefire:test --define karate.env=dev
```

To run the tests against the `TEST` environment:

```bash
mvn clean test-compile surefire:test --define karate.env=test
```

The difference between the DEV and TEST environment is whether `http` or `https` for the API endpoint is used.

| Environment | API Endpoint                           |
|-------------|----------------------------------------|
| DEV         | <http://jsonplaceholder.typicode.com>  |
| TEST        | <https://jsonplaceholder.typicode.com> |

To enforce that `karate.env` is defined, and has a value for which an environment specific configuration file exists, the following is present within
[karate-config.js](src/test/resources/karate-config.js):

```JavaScript
function() {
    // Validate that karate.env is defined and valid (karate-config-{karate.env}.js file exists)
    if (!karate.env) {
        throw new Error("'karate.env' is not defined. Please use '--define karate.env=value' where 'value' is one of the available environments");
    }
    try {
        var configFileName = 'classpath:karate-config-' + karate.env + '.js';
        var contents = read(configFileName);
        // NOTE: If file does not exist, then exception is thrown
    } catch (error) {
        throw new Error("The environment '" + karate.env + "' configuration file '" + configFileName + "' does not exist\n" + error);
    }
    :
}
```

This will validate the following:

- If karate.env is not defined, an error is thrown.
- If the environment specific configuration file `classpath:karate-config-{ENV}.js` does not exist, an error is thrown.

> NOTE: Use of `run-test.sh` (see below for details) will ensure that `karate.env` is always defined.

## Karate (API/UI)

### Feature Files

Example feature files are present to test the available APIs.

| API Tests    | Feature File                                                                                                  |
|--------------|---------------------------------------------------------------------------------------------------------------|
| `posts` API  | [src/test/resources/features/api-posts/posts.feature](src/test/resources/features/api-posts/posts.feature)    |
| `users` API  | [src/test/resources/features/api-users/users.feature](src/test/resources/features/api-users/users.feature)    |
| `todos` API  | [src/test/resources/features/api-todos/todos.feature](src/test/resources/features/api-todos/todos.feature)    |
| `photos` API | [src/test/resources/features/api-photos/photos.feature](src/test/resources/features/api-photos/photos.feature) |

### Shared Feature Files

If a scenario has to perform similar steps, you can encapsulate these steps within a `shared` scenario.

Shared scenarios should be saved within the [shared](src/test/resources/shared) folder, which is a sibling to the
main features file folder [features](src/test/resources/features).

> NOTE: Only define a single scenario within the shared feature file.

The framework includes an example of a shared scenario, [src/test/resources/shared/get-authorisation-bearer-token.feature](src/test/resources/shared/get-authorisation-bearer-token.feature), which sets up the Authorization header
value to an example [JWT](https://jwt.io) token.

The shared scenario is used within the `posts` API feature file [src/test/resources/features/api-posts/posts.feature](src/test/resources/features/api-posts/posts.feature).

The shared scenario is called here:

```karate
Background:
    * def auth = callonce read('classpath:shared/get-authorisation-bearer-token.feature')
```

> NOTE: [callonce](https://github.com/intuit/karate#callonce) is used to ensure that this is only called once within the feature file.
> If [call](https://github.com/intuit/karate#call) is used instead of `callonce` it would be called for each scenario present within the feature file.

And the `auth.headers` value used within each scenario:

```karate
Scenario: ...
    Given url jsonPlaceHolderUrl
    And headers auth.headers
```

### Tags Used

The following tags have been used within the feature files:

| Tag         | Description                              |
|-------------|------------------------------------------|
| @POSTS-API  | Test `posts` API                         |
| @USERS-API  | Test `users` API                         |
| @TODOS-API  | Test `todos` API                         |
| @PHOTOS-API | Test `photos` API                        |
| @LIST       | API calls which return a list of results |
| @SMOKE      | Simple smoke tests                       |
| @BINARY     | Validate binary results (PNG images)     |

### Test Runner

A tag based test runner is used, where all feature files are processed, and tags are used to determine which test are run.

The TagBasedApiRunner, defined within [TagBasedApiRunner.java](./src/test/java/runner/TagBasedApiRunner.java), allows all or a subset, using tags,
of tests to be run, with HTML report generated after the tests have been run.

#### System Properties Used by Tag Based Test Runner

The following Java system properties are used to control how Karate tests are run:

| System Property Name                | Default                                                                       | Description                                                                                        |
|-------------------------------------|-------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| apitest.fail.if.failures            | true                                                                          | Whether to fail TagBasedTestRunner tests if 1 or more scenarios failed                             |
| apitest.feature.paths               | classpath:features/                                                           | Folder containing the features files to process. Comma separated list of folders can be specified  |
| apitest.git.branch                  |                                                                               | Name of git branch being used. Added to HTML report.                                               |
| apitest.git.commit.hash             |                                                                               | Hash of last commit on branch. Added to HTML report.                                               |
| apitest.git.dirty                   |                                                                               | Whether there are uncommitted changes present. Added to HTML report.                               |
| apitest.git.repository.url          |                                                                               | URL of git repository being used. Added to HTML report.                                            |
| apitest.host                        | Host name using InetAddress or HOSTNAME or COMPUTERNAME environment variables | Name of host on which tests are run. Added to HTML report.                                         |
| apitest.html.report.generate        | true                                                                          | Whether to generate HTML report                                                                    |
| apitest.html.report.parent.dir      | ./target                                                                      | Directory in which cucumber-html-reports directory in which HTML report is created.                |
| apitest.html.report.title           | API Tests                                                                     | Title of HTML report                                                                               |
| apitest.ignore                      | true                                                                          | Whether to ignore tests tagged with @ignore or @IGNORE                                             |
| apitest.json.report.dir             | ./target/surefire-reports                                                     | Location of JSON result files created by Karate                                                    |
| apitest.no.data                     | true                                                                          | Whether to ignore tests tagged with @NO-DATA                                                       |
| apitest.no.data.env                 | true                                                                          | Whether to ignore tests tagged with @NO-DATA-{ENV}                                                 |
| apitest.tags                        |                                                                               | Tags to process - Use '&' to use 'and' and ',' to use 'or'                                         |
| apitest.threads                     | 1                                                                             | Number of tests which can be run in parallel                                                       |
| apitest.user                        | Value of USER or USERNAME environment variables                               | Name of user running tests. Added to HTML report.                                                  |

### System Properties Used by Karate Configuration

The following Java system properties are used to control how Karate is configured:

| System Property Name                              | Default                                             | Description                                       |
|---------------------------------------------------|-----------------------------------------------------|---------------------------------------------------|
| apitest.configure.logPrettyRequest                | true                                                | Value used for karate configure logPrettyRequest  |
| apitest.configure.logPrettyResponse               | true                                                | Value used for karate configure logPrettyResponse |
| apitest.configure.ssl                             | true                                                | Value used for karate configure ssl               |
| apitest.db.username                               | esys                                                | jdbc username                                     |
| apitest.db.password                               | *****                                               | jdbc password                                     |
| apitest.db.url                                    | jdbc:oracle:thin:@mexadb01-vip.sro.vic.gov.au:1521  | jdbc url                                          |
| apitest.db.database                               | mannyuat                                            | jdbc SID (database name)                          |
| apitest.configure.connection.timeout.milliseconds | apitest.configure.connection.timeout.seconds * 1000 | Connection timeout value in milliseconds          |
| apitest.configure.connection.timeout.seconds      | 0                                                   | Connection timeout value in seconds               |
| apitest.configure.proxy.non.proxy.hosts           |                                                     | CSV list of host names which will not be proxied  |
| apitest.configure.proxy.password                  |                                                     | Password required for proxy                       |
| apitest.configure.proxy.uri                       |                                                     | Proxy URI (protocol, host and port)               |
| apitest.configure.proxy.username                  |                                                     | Username required for proxy                       |
| apitest.configure.read.timeout.milliseconds       | apitest.configure.read.timeout.seconds * 1000       | Read timeout value in milliseconds                |
| apitest.configure.read.timeout.seconds            | 0                                                   | Read timeout value in seconds                     |

See [karate-config.js](src/test/resources/karate-config.js).

### System Properties Used by Karate Environment Configuration

The following Java system properties override the pre-configured environment values:

| System Property Name                | Description                                                                                        |
|-------------------------------------|----------------------------------------------------------------------------------------------------|
| apitest.jsonPlaceHolderUrl          | Override endpoint for JSON Placeholder site                                                        |

See [karate-config-dev.js](src/test/resources/karate-config-dev.js) and [karate-config-test.js](src/test/resources/karate-config-test.js).

### Running Tests From The Command Line Using Maven

To run the `posts` api tests:

```bash
mvn clean test-compile surefire:test --define karate.env=dev --define apitest.tags=@POSTS-API
```

To run the `users` api tests:

```bash
mvn clean test-compile surefire:test --define karate.env=dev --define apitest.tags=@USERS-API
```

To run the `todos` api tests:

```bash
mvn clean test-compile surefire:test --define karate.env=dev --define apitest.tags=@TODOS-API
```

To run the `photos` api tests:

```bash
mvn clean test-compile surefire:test --define karate.env=dev--define apitest.tags=@PHOTOS-API
```

To run the `posts` and `photos` api tests:

```bash
mvn clean test-compile surefire:test --define karate.env=dev --define apitest.tags=@POSTS-API,@PHOTOS-API
```

### Running Tests From The Command Line Using run-test.sh

The bash script [run-tests.sh](./run-tests.sh) will simplify running tests, as it will:

- Specify the DEV environment by default, unless overridden on the command line.
- Run all tests, unless overridden on the command line.
- Save textual output, JSON/XML result files, and HTML report within the [results](./results) folder as timestamped files and folders.
- exit code of script reflects whether there are test failures reported.

Script usage can be displayed using:

``` bash
./run-tests.sh --help
```

To run all Karate tests within the DEV environment:

```bash
./run-tests.sh --test-mode karate
```

To run all Karate tests within the TEST environment:

```bash
./run-tests.sh --test-mode karate --env test
```

To run all Karate `posts` tests, tagged with @POSTS-API, within DEV environment:

```bash
./run-tests.sh --test-mode karate --tag @POSTS-API
```

To run all Karate `posts` and all `photos` tests, tagged with @POSTS-API or @PHOTOS-API, within the DEV environment:

```bash
./run-tests.sh --test-mode karate --tag @POSTS-API --tag @PHOTOS-API
```

To run all Karate tests within [features/api-users](src/test/resources/features/api-users) folder, within the DEV environment:

```bash
./run-tests.sh --test-mode karate --feature classpath:features/api-users
```

To run all Karate smoke tests within TEST environment:

```bash
./run-tests.sh --test-mode karate --tag @SMOKE
```

To run all Karate smoke tests for the `todos` API within TEST environment:

```bash
./run-tests.sh --test-mode karate --tag @SMOKE --tag @TODOS-API --and-tags --env test
```

To run all Karate tests within the DEV environment through the proxy <http://localhost:8500>:

```bash
./run-tests.sh --test-mode karate -- --define apitest.configure.proxy.uri=http://localhost:8500
```

> The use of `--` is important, as it stops `run-tests.sh` from processing arguments on the command line, allowing the remaining arguments to be appended
> to the Maven command.

## Gatling (Performance)

To run all Gatling tests within the DEV environment:

```bash
./run-tests.sh --test-mode gatling
```

To run all Gatling tests within the TEST environment:

```bash
./run-tests.sh --test-mode gatling --env test
```

## Verifying Karate and Gatling

To verify Karate by running a simple test:

```bash
./run-tests.sh --test-mode verify-karate
```

To verify Gatling by running a simple test:

```bash
./run-tests.sh --test-mode verify-gatling
```
