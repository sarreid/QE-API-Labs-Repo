function() {
    // define configuration information to be overridden for the DEV environment
    karate.log('Setting up configuration for ' + karate.env.toUpperCase() + ' environment');
    return {
        jsonPlaceHolderUrl: Support.getProperty('apitest.jsonPlaceHolderUrl', 'http://jsonplaceholder.typicode.com')
    }
}
