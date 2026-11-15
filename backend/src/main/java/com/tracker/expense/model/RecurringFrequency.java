package com.tracker.expense.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum RecurringFrequency {
    DAILY("daily"),
    WEEKLY("weekly"),
    MONTHLY("monthly"),
    YEARLY("yearly");

    private final String value;

    RecurringFrequency(String value) {
        this.value = value;
    }

    @JsonValue
    public String getValue() {
        return value;
    }

    @JsonCreator
    public static RecurringFrequency fromValue(String value) {
        if (value == null) {
            return null;
        }
        for (RecurringFrequency freq : values()) {
            if (freq.value.equalsIgnoreCase(value) || freq.name().equalsIgnoreCase(value)) {
                return freq;
            }
        }
        throw new IllegalArgumentException("Unknown recurring frequency: " + value);
    }
}
