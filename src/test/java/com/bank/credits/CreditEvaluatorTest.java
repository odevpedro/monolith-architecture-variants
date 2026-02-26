package com.bank.credits;

import com.bank.credits.application.rules.CreditEvaluator;
import com.bank.credits.domain.CreditDecision;
import com.bank.customers.domain.Customer;
import org.junit.jupiter.api.Test;
import java.lang.reflect.Field;
import java.math.BigDecimal;
import static org.assertj.core.api.Assertions.assertThat;

/**
 * Regra de negocio pura — zero Spring, zero banco, zero e-mail.
 * Compare com traditional onde testar exige PostgreSQL + SMTP rodando.
 */
class CreditEvaluatorTest {

    private final CreditEvaluator evaluator = new CreditEvaluator();

    @Test void shouldApproveFullAmountWhenScoreAbove700() throws Exception {
        CreditDecision d = evaluator.evaluate(customerWithScore(750), new BigDecimal("10000"));
        assertThat(d.isApproved()).isTrue();
        assertThat(d.getApprovedAmount()).isEqualByComparingTo("10000");
    }

    @Test void shouldApproveHalfAmountWhenScoreBetween500And700() throws Exception {
        CreditDecision d = evaluator.evaluate(customerWithScore(600), new BigDecimal("10000"));
        assertThat(d.isApproved()).isTrue();
        assertThat(d.getApprovedAmount()).isEqualByComparingTo("5000");
    }

    @Test void shouldRejectWhenScoreBelow500() throws Exception {
        CreditDecision d = evaluator.evaluate(customerWithScore(400), new BigDecimal("10000"));
        assertThat(d.isApproved()).isFalse();
        assertThat(d.getRejectionReason()).contains("400");
    }

    private Customer customerWithScore(int score) throws Exception {
        Customer c = Customer.class.getDeclaredConstructor().newInstance();
        Field f = Customer.class.getDeclaredField("creditScore");
        f.setAccessible(true);
        f.set(c, score);
        return c;
    }
}
