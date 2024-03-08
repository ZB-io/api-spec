
  package app.api;;

  import app.App;
  import com.intuit.karate.Results;
  import com.intuit.karate.Runner;
  import com.intuit.karate.http.HttpServer;
  import com.intuit.karate.http.ServerConfig;
  import org.junit.jupiter.api.Test;

  import static org.junit.jupiter.api.Assertions.assertEquals;

  class ApiTest {

      @Test
      void testAll() {
          ServerConfig config = App.serverConfig("src/main/java/app");
          HttpServer server = HttpServer.config(config).build();
          Results results = Runner.path("classpath:/var/tmp/Roost/RoostGPT/karate/c4d04e56-58cb-4366-a405-546def38a1fe/source/api-spec/api_tests/nobelPrize_category_year_get_karate.feature")
                  .systemProperty("url.base", "http://localhost:" + server.getPort())
                  .parallel(1);
          assertEquals(0, results.getFailCount(), results.getErrorMessages());
      }

  }
