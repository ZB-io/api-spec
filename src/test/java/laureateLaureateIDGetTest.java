
  package app.api_tests;

  // import app.App;
  import com.intuit.karate.Results;
  import com.intuit.karate.Runner;
  import com.intuit.karate.http.HttpServer;
  import com.intuit.karate.http.ServerConfig;
  import org.junit.jupiter.api.Test;

  import static org.junit.jupiter.api.Assertions.assertEquals;

  class laureateLaureateIDGetTest {

      @Test
      void testAll() {
          // ServerConfig config = App.serverConfig("src/main/java/app");
          // HttpServer server = HttpServer.config(config).build();
          String apiHostServer = System.getenv.getOrDefault("API_HOST", "http://localhost:8080");
          Results results = Runner.path("classpath:/api_tests/laureate_laureateID_get.feature")
                  .systemProperty("url.base", apiHostServer)
                  .parallel(1);
          assertEquals(0, results.getFailCount(), results.getErrorMessages());
      }

  }
