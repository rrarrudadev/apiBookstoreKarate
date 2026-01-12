package runner;

import com.intuit.karate.junit5.Karate;

class TestRunnerTest {

    @Karate.Test
    Karate testAll() {
        return Karate.run("classpath:account", "classpath:bookstore");
    }
}
