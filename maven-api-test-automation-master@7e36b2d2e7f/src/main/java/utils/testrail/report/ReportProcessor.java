package utils.testrail.report;

import com.google.gson.Gson;
import utils.testrail.report.model.Element;
import utils.testrail.report.model.JsonReport;
import utils.testrail.report.model.Step;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class ReportProcessor {

    public HashMap<String, HashMap<String, Object>> analyseReports() {
        List<JsonReport[]> reports = getReports();
        HashMap<String, HashMap<String, Object>> results = new HashMap<>();
        for (JsonReport[] featureReport : reports) {
            for (JsonReport scenarioReport : featureReport) {
                List<Element> elements = scenarioReport.getElements();
                for (Element element : elements) {
                    HashMap<String, Object> scenario = new HashMap<>();
                    scenario.put("name", element.getName());
                    scenario.put("result", getResult(element));
                    results.put(extractTestIdFromName(element.getName()), scenario);
                }
            }
        }
        return results;
    }

    private List<JsonReport[]> getReports() {
        List<String> files = getAllJsons();
        List<JsonReport[]> allReports = new ArrayList<>();
        Gson gson = new Gson();
        for (String file : files) {
            JsonReport[] reports = gson.fromJson(readFile(file), JsonReport[].class);
            allReports.add(reports);
        }
        return allReports;
    }

    private HashMap<String, Object> getResult(Element element) {
        HashMap<String, Object> result = new HashMap<>();
        String status = "passed";
        StringBuilder message = new StringBuilder();
        for (Step step : element.getSteps()) {
            if (!step.getResult().getStatus().equalsIgnoreCase("passed")) {
                status = "failed";
            }

            String stepMessage = step.getResult().getErrorMessage();

            if (stepMessage != null) {
                message.append("\n").append(stepMessage);
            }
        }
        result.put("status", status);
        result.put("message", message);
        return result;
    }

    private String extractTestIdFromName(String testName) {
        String[] parts = testName.split("-");
        if (parts.length >= 1) {
            return parts[0].trim().toLowerCase()
                    .replace("[", "")
                    .replace("]", "")
                    .replace("c", "");
        }
        return null;
    }


    private List<String> getAllJsons() {
        List<String> jsonFiles = new ArrayList<>();
        File folder = new File("./target/surefire-reports");
        File[] files = folder.listFiles();
        if (files == null) return jsonFiles;
        for (File file : files) {
            if (file.getName().endsWith(".json")) {
                jsonFiles.add(file.getAbsolutePath());
            }
        }
        return jsonFiles;
    }

    private String readFile(String path) {
        try {
            return new String(Files.readAllBytes(Paths.get(path)));
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }
}
