package utils.testrail.report.model;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

public class DocString {
    @SerializedName("content_type")
    @Expose
    private String contentType;
    @SerializedName("value")
    @Expose
    private String value;
    @SerializedName("line")
    @Expose
    private Integer line;

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public String getValue() {
        return value;
    }

    public void setValue(String value) {
        this.value = value;
    }

    public Integer getLine() {
        return line;
    }

    public void setLine(Integer line) {
        this.line = line;
    }
}
