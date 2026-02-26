package com.bank.credits.api.dto;

import com.bank.credits.domain.Credit;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public record CreditResponse(
    String id, String customerId,
    BigDecimal requestedAmount, BigDecimal approvedAmount,
    String status, LocalDateTime createdAt
) {
    public static CreditResponse from(Credit c) {
        return new CreditResponse(c.getId(), c.getCustomerId(),
            c.getRequestedAmount(), c.getApprovedAmount(),
            c.getStatus().name(), c.getCreatedAt());
    }
}
