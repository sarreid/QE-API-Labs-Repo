package verify

/**
 * This Gatling simulation is used to verify that:
 *
 *    - Scala code compiles
 *    - this simulation is run successfully, which invokes the Karate check feature file (so it check Karate configuration setup)
 */

import com.intuit.karate.gatling.KarateProtocol
import com.intuit.karate.gatling.PreDef._
import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder

import scala.concurrent.duration._

class Check extends Simulation {

    val vUsers = 1
    val duration: FiniteDuration = 10 seconds
    
    // 100 % of requests are successful - note this means Karate tests are successful (not http status code = 2xx) 
    val successfulRequestsPercent = 100

    // Define Scenarios
    val performanceTest: ScenarioBuilder = scenario("posts").exec(karateFeature("classpath:features/verify/simple-check.feature", "@CHECK"))
    
    setUp(
        performanceTest.inject(
          rampUsers(vUsers) during duration
        )
    )
    .assertions(
        global.successfulRequests.percent.is(successfulRequestsPercent)
    )
}
