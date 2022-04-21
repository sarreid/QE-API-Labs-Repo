package utils.testrail.exceptions;

public class NoTestRailUrlException extends Exception {
    private static final long serialVersionUID = 1L;

    public NoTestRailUrlException(String message) {
        super(message);
    }
}
