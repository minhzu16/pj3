package com.tracker.expense.job;

import com.tracker.expense.service.RecurringService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

@Slf4j
@Component
@RequiredArgsConstructor
public class RecurringJobRunner {

    private final RecurringService recurringService;

    // Runs every day at 00:05 AM
    @Scheduled(cron = "${app.jobs.recurring-cron:0 5 0 * * *}")
    public void runDailyRecurringJob() {
        LocalDate today = LocalDate.now();
        log.info("Starting scheduled recurring transactions job for date: {}", today);
        try {
            int generated = recurringService.processRecurringRules(today);
            log.info("Scheduled recurring job finished successfully. Generated {} transactions.", generated);
        } catch (Exception ex) {
            log.error("Error occurred while processing recurring transactions", ex);
        }
    }
}
