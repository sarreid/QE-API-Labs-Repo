package performance

import com.intuit.karate.gatling.KarateProtocol
import com.intuit.karate.gatling.PreDef._
import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder

import scala.concurrent.duration._

class Todos403Scenario_EXAMPLE_14 extends Simulation {

    val vUsers = 100
    val duration: FiniteDuration = 10 seconds
    
    // set percentile and maximum response time
    var responseTimePercentile: Int = 0
    var responseTimeMilliseconds: Int = 0

    // Maximum response time
    var maxResponseTimeMilliseconds: Int = 0

    val environment: String = System.getProperty("karate.env")
    if (environment == "dev") {
        responseTimePercentile = 95
        responseTimeMilliseconds = 150
        maxResponseTimeMilliseconds = 250
    } else if (environment == "test") {
        responseTimePercentile = 95
        responseTimeMilliseconds = 70
        maxResponseTimeMilliseconds = 150
    } else {
        throw new IllegalArgumentException(s"No metrics have been defined for environment '$environment'")
    }

    // 100 % of requests are successful - note this means Karate tests are successful (not http status code = 2xx) 
    val successfulRequestsPercent = 100

    // Set API Paths
    val protocol: KarateProtocol = karateProtocol(
        "/todos/{id}" -> Nil,
        "/todos" -> Nil
    )

    // Get Transaction names
    protocol.nameResolver = (req, ctx) => req.getHeader("karate-name")

    // Define Scenarios
    val performanceTest: ScenarioBuilder = scenario("posts").exec(karateFeature("classpath:features/api-todos/todos.feature", "@NEGATIVE"))
    
    setUp(
        performanceTest.inject(
          rampUsers(vUsers) during duration
        )
    )
        .protocols(protocol)
        .assertions(
            global.responseTime.percentile(responseTimePercentile).lte(responseTimeMilliseconds),
            global.responseTime.max.lte(maxResponseTimeMilliseconds),
            global.successfulRequests.percent.is(successfulRequestsPercent)
    )
}
