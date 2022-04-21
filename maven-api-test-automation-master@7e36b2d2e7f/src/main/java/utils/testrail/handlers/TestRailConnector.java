package utils.testrail.handlers;

import com.codepine.api.testrail.TestRail;
import com.codepine.api.testrail.model.*;
import utils.testrail.exceptions.NoTestRailUrlException;
import utils.testrail.exceptions.ProjectNotFoundException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class TestRailConnector {
    TestRail testRail;

    public TestRailConnector(String testRailUrl, Credential credential) throws NoTestRailUrlException {
        if (testRailUrl == null) {
            throw new NoTestRailUrlException("There is no configured TestRail url!");
        }
        this.testRail = TestRail.builder(testRailUrl, credential.getUser(), credential.getPass()).build();
    }

    public Project getProject(String name) throws ProjectNotFoundException {
        List<Project> projects = this.testRail.projects().list().execute();
        for (Project project : projects) {
            if (project.getName().equalsIgnoreCase(name)) {
                return project;
            }
        }
        throw new ProjectNotFoundException("Cannot find project name: " + name);
    }

    public List<Case> getTestCases(Project project) {
        return this.testRail.cases().list(project.getId(), getTestCaseField()).execute();
    }

    public List<Run> getRuns(Project project) {
        return this.testRail.runs().list(project.getId()).execute();
    }

    public Case getTestCaseById(Project project, int testCaseId) {
        return testRail.cases().get(testCaseId, getTestCaseField()).execute();
    }

    public Run createTestRun(Project project, String testRunName) {
        return testRail.runs().add(project.getId(), new Run().setName(testRunName).setIncludeAll(false)).execute();
    }

    public Run createTestRun(Project project, String testRunName, Integer milestoneId) {
        return testRail.runs().add(project.getId(), new Run().setName(testRunName).setMilestoneId(milestoneId).setIncludeAll(false)).execute();
    }

    public void addTestResult(Run testRun, Case testCase, TestResults result) {
        int testResultId = getStatusIdByResult(result);
        this.testRail.results().addForCase(testRun.getId(), testCase.getId(), new Result().setStatusId(testResultId), getResultFields()).execute();
    }

    public void addTestResult(Run testRun, Case testCase, TestResults result, HashMap<String, Object> customFields) {
        int testResultId = getStatusIdByResult(result);
        this.testRail.results().addForCase(testRun.getId(), testCase.getId(), new Result().setStatusId(testResultId).setCustomFields(customFields), getResultFields()).execute();
    }

    public void addTestResult(Run testRun, Case testCase, Result result) {
        this.testRail.results().addForCase(testRun.getId(), testCase.getId(), result, getResultFields()).execute();
    }

    public void addTestResult(Run testRun, Case testCase, String result) {
        this.testRail.results().addForCase(testRun.getId(), testCase.getId(), new Result().setStatusId(getStatusId(result)), getResultFields()).execute();
    }

    public void addTestResult(Run testRun, Case testCase, String result, String comment) {
        this.testRail.results().addForCase(testRun.getId(), testCase.getId(), new Result().setStatusId(getStatusId(result)).setComment(comment), getResultFields()).execute();
    }

    public void addTestCaseToTestRun(Run testRun, Integer testCaseId) {
        List<Integer> currentCaseIds = new ArrayList<>();
        List<Test> currentTests = this.testRail.tests().list(testRun.getId()).execute();
        for (Test test : currentTests) {
            currentCaseIds.add(test.getCaseId());
        }
        currentCaseIds.add(testCaseId);
        testRun.setIncludeAll(false);
        testRun.setCaseIds(currentCaseIds);
        testRail.runs().update(testRun).execute();
    }

    public Run getTestRunById(int id) {
        return testRail.runs().get(id).execute();
    }

    private List<CaseField> getTestCaseField() {
        return this.testRail.caseFields().list().execute();
    }

    private List<ResultField> getResultFields() {
        return this.testRail.resultFields().list().execute();
    }

    public int getStatusIdByResult(TestResults result) {
        switch (result) {
            case Passed:
                return 1;
            case Blocked:
                return 2;
            case Retest:
                return 4;
            case Failed:
                return 5;
            default:
                return 3;
        }
    }

    public int getStatusId(String result) {
        switch (result.toLowerCase()) {
            case "passed":
                return 1;
            case "failed":
                return 5;
            default:
                return 3;
        }
    }

    public TestRail getTestRail() {
        return testRail;
    }
}
