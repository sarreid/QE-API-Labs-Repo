package utils.config;

import com.microsoft.azure.keyvault.KeyVaultClient;
import com.microsoft.azure.keyvault.models.SecretBundle;
import org.apache.log4j.Logger;
import org.jasypt.encryption.pbe.StandardPBEStringEncryptor;
import org.jasypt.properties.EncryptableProperties;
import utils.testrail.Constants;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.URL;
import java.util.Properties;

public class ConfigManager {
    private final Logger logger = Logger.getLogger(this.getClass());
    private Properties azureConfigProperties;
    private Properties testRailConfigProperties;

    public ConfigManager() throws IOException {
        String testRailConfigFile = getConfigFilePath(Constants.TESTRAIL_CONFIG_FILE);
        String azureConfigFile = getConfigFilePath(Constants.AZURE_CONFIG_FILE);
        this.azureConfigProperties = loadNonEncProperties(azureConfigFile);
        this.testRailConfigProperties = loadEncProperties(testRailConfigFile);
    }

    public Properties getTestRailConfigProperties() {
        return testRailConfigProperties;
    }

    private Properties loadNonEncProperties(String file) throws IOException {
        StandardPBEStringEncryptor encryption = new StandardPBEStringEncryptor();
        Properties properties = new EncryptableProperties(encryption);
        FileInputStream fileInputStream = new FileInputStream(file);
        properties.load(fileInputStream);
        return properties;
    }

    private Properties loadEncProperties(String file) throws IOException {
        StandardPBEStringEncryptor encryption = new StandardPBEStringEncryptor();
        SecretBundle clientSecretKeyVaultCredential = getKeyVaultSecretClient();
        encryption.setPassword(clientSecretKeyVaultCredential.value());
        Properties properties = new EncryptableProperties(encryption);
        FileInputStream fileInputStream = new FileInputStream(file);
        properties.load(fileInputStream);
        return properties;
    }

    private String getConfigFilePath(String filename) throws FileNotFoundException {
        ClassLoader classLoader = this.getClass().getClassLoader();
        URL url = classLoader.getResource(filename);
        if (url == null) {
            logger.error("There is no configuration file!");
            throw new FileNotFoundException();
        }
        return url.getPath();
    }

    private SecretBundle getKeyVaultSecretClient() {
        ClientSecretKeyVaultCredential clientSecretKeyVaultCredential = new ClientSecretKeyVaultCredential(
                this.azureConfigProperties.getProperty(Constants.AZURE_KV_CLIENT_ID),
                this.azureConfigProperties.getProperty(Constants.AZURE_KV_CLIENT_KEY));
        KeyVaultClient keyVaultClient = new KeyVaultClient(clientSecretKeyVaultCredential);
        return keyVaultClient.getSecret(this.azureConfigProperties.getProperty(Constants.AZURE_KV_URL), Constants.SECRET_NAME);
    }
}
