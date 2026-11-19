package com.tracker.expense.config;

import org.flywaydb.core.api.Location;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.flyway.FlywayConfigurationCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;
import java.util.stream.Stream;

/**
 * The demo accounts (demo@example.com and test@example.com, password "Password123!") live in
 * db/demo and are only migrated with DEMO_MODE=true, never in a default deployment.
 */
@Configuration
public class DemoDataConfig {

    static final Location DEMO_LOCATION = new Location("classpath:db/demo");

    @Bean
    FlywayConfigurationCustomizer demoDataMigrations(@Value("${app.demo.enabled:false}") boolean demoEnabled) {
        return configuration -> {
            if (demoEnabled) {
                configuration.locations(Stream.concat(Arrays.stream(configuration.getLocations()), Stream.of(DEMO_LOCATION))
                        .toArray(Location[]::new));
            }
        };
    }
}
