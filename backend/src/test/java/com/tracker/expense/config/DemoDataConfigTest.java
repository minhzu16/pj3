package com.tracker.expense.config;

import org.flywaydb.core.api.Location;
import org.flywaydb.core.api.configuration.FluentConfiguration;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;

class DemoDataConfigTest {

    // Order is irrelevant: Flyway sorts migrations by version across all locations.
    private Set<String> locations(boolean demoEnabled) {
        FluentConfiguration configuration = new FluentConfiguration().locations("classpath:db/migration");
        new DemoDataConfig().demoDataMigrations(demoEnabled).customize(configuration);
        return Arrays.stream(configuration.getLocations()).map(Location::getDescriptor).collect(Collectors.toSet());
    }

    @Test
    void defaultDeploymentsOnlyRunTheCoreMigrations() {
        assertEquals(Set.of("classpath:db/migration"), locations(false));
    }

    @Test
    void demoModeAddsTheDemoSeed() {
        assertEquals(Set.of("classpath:db/migration", "classpath:db/demo"), locations(true));
    }

    @Test
    void theDemoSeedIsNotInTheCoreMigrationFolder() {
        assertNull(getClass().getResource("/db/migration/V2__seed_demo_data.sql"));
        assertNotNull(getClass().getResource("/db/demo/V2__seed_demo_data.sql"));
    }
}
