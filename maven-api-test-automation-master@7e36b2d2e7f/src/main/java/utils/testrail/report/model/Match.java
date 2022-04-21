package utils.testrail.report.model;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

import java.util.List;

public class Match {
    @SerializedName("location")
    @Expose
    private String location;
    @SerializedName("arguments")
    @Expose
    private List<Object> arguments = null;

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public List<Object> getArguments() {
        return arguments;
    }

    public void setArguments(List<Object> arguments) {
        this.arguments = arguments;
    }
}
