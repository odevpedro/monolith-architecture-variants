package com.bank.credits.domain;

import java.math.BigDecimal;

public class CreditDecision {
    private final boolean approved;
    private final BigDecimal approvedAmount;
    private final String rejectionReason;

    private CreditDecision(boolean approved, BigDecimal approvedAmount, String rejectionReason) {
        this.approved = approved;
        this.approvedAmount = approvedAmount;
        this.rejectionReason = rejectionReason;
    }

    public static CreditDecision approved(BigDecimal amount) {
        return new CreditDecision(true, amount, null);
    }
    public static CreditDecision rejected(String reason) {
        return new CreditDecision(false, BigDecimal.ZERO, reason);
    }

    public boolean isApproved() { return approved; }
    public BigDecimal getApprovedAmount() { return approvedAmount; }
    public String getRejectionReason() { return rejectionReason; }
}
