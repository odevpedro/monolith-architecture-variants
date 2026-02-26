package com.bank.credits.application;

import com.bank.credits.domain.Credit;
import com.bank.credits.domain.CreditDecision;
import com.bank.credits.infrastructure.JpaCreditRepository;
import com.bank.credits.infrastructure.clients.CustomerServiceClient;
import com.bank.credits.infrastructure.clients.NotificationServiceClient;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.Map;

/**
 * MONOLITO DISTRIBUIDO - cadeia sincrona de chamadas HTTP.
 *
 * Latencia acumulada por operacao:
 *   customerClient.getCustomer()          ~200ms
 *   jdbcTemplate (banco compartilhado)     ~50ms
 *   notificationClient.sendCreditResult() ~100ms
 *   Total minimo:                         ~350ms
 *
 * Se qualquer chamada falhar: 500 Error + possivel estado inconsistente.
 */
@Service
@Transactional
public class CreditService {

    private final JpaCreditRepository creditRepository;
    private final CustomerServiceClient customerClient;
    private final NotificationServiceClient notificationClient;
    private final JdbcTemplate jdbcTemplate; // banco compartilhado entre "servicos"

    public CreditService(JpaCreditRepository creditRepository,
                         CustomerServiceClient customerClient,
                         NotificationServiceClient notificationClient,
                         JdbcTemplate jdbcTemplate) {
        this.creditRepository = creditRepository;
        this.customerClient = customerClient;
        this.notificationClient = notificationClient;
        this.jdbcTemplate = jdbcTemplate;
    }

    public Credit requestCredit(String customerId, BigDecimal amount) {

        // Chamada HTTP 1 - trava se customer-service estiver lento
        Map<String, Object> customer = customerClient.getCustomer(customerId);
        int creditScore = ((Number) customer.get("creditScore")).intValue();
        String email = (String) customer.get("email");

        // Acessa banco compartilhado - dois "servicos" no mesmo schema
        Integer activeCredits = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM credits WHERE customer_id = ? AND status = 'APPROVED'",
            Integer.class, customerId);

        CreditDecision decision;
        if (creditScore >= 700 && activeCredits < 3)
            decision = CreditDecision.approved(amount);
        else if (creditScore >= 500 && activeCredits < 2)
            decision = CreditDecision.approved(amount.multiply(new BigDecimal("0.5")));
        else
            decision = CreditDecision.rejected("Score insuficiente ou limite de creditos atingido");

        Credit credit = Credit.create(customerId, amount);
        if (decision.isApproved()) credit.approve(decision.getApprovedAmount());
        else credit.reject(decision.getRejectionReason());

        Credit saved = creditRepository.save(credit); // credito salvo no banco

        // Chamada HTTP 2 - se cair aqui: credito salvo + API retorna 500
        notificationClient.sendCreditResult(email, saved.getId(), saved.getStatus().name());

        return saved;
    }
}
