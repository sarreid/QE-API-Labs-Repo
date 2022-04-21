package utils.testrail.exceptions;

public class ProjectNotFoundException extends Exception {
    private static final long serialVersionUID = 1L;

    public ProjectNotFoundException(String message) {
        super(message);
    }
}
