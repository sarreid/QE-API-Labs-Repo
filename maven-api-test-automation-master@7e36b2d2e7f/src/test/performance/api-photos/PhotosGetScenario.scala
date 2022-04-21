package performance

import com.intuit.karate.gatling.KarateProtocol
import com.intuit.karate.gatling.PreDef._
import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder

import scala.concurrent.duration._

class PhotosGetScenario_EXAMPLE_11 extends Simulation {

    val vUsers: Int = 100
    val duration: FiniteDuration = 10 seconds

    // set percentile and maximum response time
    var responseTimePercentile: Int = 0
    var responseTimeMilliseconds: Int = 0

    // Maximum response time
    var maxResponseTimeMilliseconds: Int = 0

    val environment: String = System.getProperty("karate.env")
    if (environment == "dev") {
        responseTimePercentile = 95
        responseTimeMilliseconds = 500
        maxResponseTimeMilliseconds = 1000
    } else if (environment == "test") {
        responseTimePercentile = 95
        responseTimeMilliseconds = 200
        maxResponseTimeMilliseconds = 500
    } else {
        throw new IllegalArgumentException(s"No metrics have been defined for environment '$environment'")
    }

    // 100 % of requests are successful - note this means Karate tests are successful (not http status code = 2xx) 
    val successfulRequestsPercent: Int = 100

    // Set API Paths
    val protocol: KarateProtocol = karateProtocol(
        "/photos/{id}" -> Nil,
        "/photos" -> Nil
    )

    // Get Transaction names
    protocol.nameResolver = (req, ctx) => req.getHeader("karate-name")

    // Define Scenarios
    val performanceTest: ScenarioBuilder = scenario("posts").exec(karateFeature("classpath:features/api-photos/photos.feature", "@LIST"))

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