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

    var Support = Java.type('utils.util.Support');

    // Setup Karate proxy settings if configured
    var proxyUri = Support.getProperty('apitest.configure.proxy.uri');
    var proxy;
    if (proxyUri) {
        proxy = {
            uri: proxyUri
        };

        var username = Support.getProperty('apitest.configure.proxy.username');
        var password = Support.getProperty('apitest.configure.proxy.password');
        if (username && (password || password === '')) {
            proxy.username = username;
            proxy.password = password;
        }

        var nonProxyHosts = Support.getPropertyList('apitest.configure.proxy.non.proxy.hosts');
        if (nonProxyHosts && nonProxyHosts.length > 0) {
            proxy.nonProxyHosts = nonProxyHosts;
        }
    }

    karate.log("=============================================================");
    karate.log("Feature File:      " + karate.info.featureFileName);
    karate.log("Scenario Type:     " + karate.info.scenarioType);
    karate.log("Scenario Name:     " + karate.info.scenarioName);
    karate.log("Environment:       " + karate.env.toUpperCase());
    if (proxy) {
        karate.log("Proxy:             " + karate.pretty(proxy));
        karate.configure('proxy', proxy);
    }
    karate.log("=============================================================");

    // Enable HTTPS calls without needing to configure a trusted certificate or key-store.
    // See https://github.com/intuit/karate#configure for more information
    karate.configure('ssl', Support.getProperty('apitest.configure.ssl', true));

    // Configure connection value - allow seconds or milliseconds to be specified
    var connectionTimeoutSeconds = Support.getProperty('apitest.configure.connection.timeout.seconds', 0);
    var connectionTimeoutMilliseconds = Support.getProperty('apitest.configure.connection.timeout.milliseconds', connectionTimeoutSeconds * 1000);
    if (connectionTimeoutMilliseconds > 0) {
        karate.log('Connection timeout (milliseconds): ' + connectionTimeoutMilliseconds);
        karate.configure('connectTimeout', connectionTimeoutMilliseconds);
    }

    // Read timeout value - allow seconds or milliseconds to be specified
    var readTimeoutSeconds = Support.getProperty('apitest.configure.read.timeout.seconds', 0);
    var readTimeoutMilliseconds = Support.getProperty('apitest.configure.read.timeout.milliseconds', readTimeoutSeconds * 1000);
    if (readTimeoutMilliseconds > 0) {
        karate.log('Read timeout (Milliseconds): ' + readTimeoutMilliseconds);
        karate.configure('readTimeout', readTimeoutMilliseconds);
    }

    // Ensure request and responses are logged as pretty
    karate.configure('logPrettyRequest', Support.getProperty('apitest.configure.logPrettyRequest', true));
    karate.configure('logPrettyResponse', Support.getProperty('apitest.configure.logPrettyResponse', true));

    // Configure log modifier - which prevents sensitive information being logged
    var LM = Java.type('runner.LogModifier');
    karate.configure('logModifier', LM.instance);

    var FakeData = Java.type('utils.util.FakeData');

    // Setup common configuration information
    return {
        fakeData: new FakeData(),
        Support: Support
    };
}
