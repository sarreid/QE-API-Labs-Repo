function() {
    // define configuration information to be overridden for the TEST environment
    karate.log('Setting up configuration for ' + karate.env.toUpperCase() + ' environment');

    return {
        jsonPlaceHolderUrl: Support.getProperty('apitest.jsonPlaceHolderUrl', 'https://jsonplaceholder.typicode.com')
    }
}
