package com.bank.credits.application.rules;

import com.bank.credits.domain.CreditDecision;
import com.bank.customers.domain.Customer;
import org.springframework.stereotype.Component;
import java.math.BigDecimal;

/**
 * Regra de negocio isolada.
 * Testavel sem Spring, sem banco, sem HTTP.
 * Qualquer mudanca na regra de aprovacao acontece AQUI e SOMENTE AQUI.
 */
@Component
public class CreditEvaluator {
    private static final int MIN_SCORE_FULL = 700;
    private static final int MIN_SCORE_PARTIAL = 500;
    private static final BigDecimal PARTIAL_FACTOR = new BigDecimal("0.5");

    public CreditDecision evaluate(Customer customer, BigDecimal requestedAmount) {
        int score = customer.getCreditScore();
        if (score >= MIN_SCORE_FULL) return CreditDecision.approved(requestedAmount);
        if (score >= MIN_SCORE_PARTIAL) return CreditDecision.approved(requestedAmount.multiply(PARTIAL_FACTOR));
        return CreditDecision.rejected("Score " + score + " abaixo do minimo de " + MIN_SCORE_PARTIAL);
    }
}
