package utils.testrail;

public class Constants {
    private Constants(){
        throw new IllegalStateException();
    }
    public static final String TESTRAIL_USER = "testrail.user";
    public static final String TESTRAIL_PASS = "testrail.key";
    public static final String PROJECT_NAME = "testrail.project";
    public static final String TESTRAIL_URL = "testrail.url";
    public static final String DATETIME_FORMAT = "default.datetime.format";
    public static final String DEFAULT_PREFIX = "default.prefix";
    public static final String BUILD_NUMBER = "BuildNumber";
    public static final String BUILD_DEFINITION = "DefinitionName";
    public static final String TESTRAIL_CONFIG_FILE = "config.properties";
    public static final String AZURE_CONFIG_FILE = "azure.properties";
    public static final String UPDATE_TESTRAIL = "testrail.update";
    public static final String AZURE_KV_URL = "azure.kv.url";
    public static final String AZURE_KV_CLIENT_ID = "azure.kv.client.id";
    public static final String AZURE_KV_CLIENT_KEY = "azure.kv.client.key";
    public static final String SECRET_NAME = "mySuperSecret";
}