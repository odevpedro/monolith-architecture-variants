package com.bank.credits.application;

import com.bank.credits.application.rules.CreditEvaluator;
import com.bank.credits.domain.Credit;
import com.bank.credits.domain.CreditDecision;
import com.bank.credits.infrastructure.JpaCreditRepository;
import com.bank.customers.application.CustomerService;
import com.bank.customers.domain.Customer;
import com.bank.notifications.application.NotificationService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class CreditService {

    private final JpaCreditRepository creditRepository;
    private final CustomerService customerService;         // interface publica do modulo customers
    private final CreditEvaluator creditEvaluator;
    private final NotificationService notificationService; // interface publica do modulo notifications

    public CreditService(JpaCreditRepository creditRepository, CustomerService customerService,
                         CreditEvaluator creditEvaluator, NotificationService notificationService) {
        this.creditRepository = creditRepository;
        this.customerService = customerService;
        this.creditEvaluator = creditEvaluator;
        this.notificationService = notificationService;
    }

    public Credit requestCredit(String customerId, BigDecimal amount) {
        // Acessa customers pela interface publica — nunca pelo JpaCustomerRepository diretamente
        Customer customer = customerService.findById(customerId)
            .orElseThrow(() -> new RuntimeException("Cliente nao encontrado: " + customerId));

        CreditDecision decision = creditEvaluator.evaluate(customer, amount);
        Credit credit = Credit.create(customerId, amount);

        if (decision.isApproved()) credit.approve(decision.getApprovedAmount());
        else credit.reject(decision.getRejectionReason());

        Credit saved = creditRepository.save(credit);
        notificationService.notifyCreditResult(customer.getEmail(), saved);
        return saved;
    }

    @Transactional(readOnly = true)
    public Optional<Credit> findById(String id) { return creditRepository.findById(id); }

    @Transactional(readOnly = true)
    public List<Credit> findByCustomer(String customerId) {
        return creditRepository.findByCustomerIdOrderByCreatedAtDesc(customerId);
    }
}
