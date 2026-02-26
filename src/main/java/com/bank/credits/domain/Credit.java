package com.bank.credits.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;


@Entity
@Table(name = "credits")
public class Credit {

    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(nullable = false)
    private String customerId;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal requestedAmount;

    @Column(precision = 15, scale = 2)
    private BigDecimal approvedAmount;

    @Enumerated(EnumType.STRING) @Column(nullable = false)
    private CreditStatus status;
    private String rejectionReason;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    protected Credit() {}

    public static Credit create(String customerId, BigDecimal requestedAmount) {
        Credit c = new Credit();
        c.customerId = customerId;
        c.requestedAmount = requestedAmount;
        c.status = CreditStatus.PENDING;
        c.createdAt = LocalDateTime.now();
        return c;
    }

    public void approve(BigDecimal amount) {
        if (!CreditStatus.PENDING.equals(this.status))
            throw new IllegalStateException("So e possivel aprovar creditos com status PENDING");
        this.approvedAmount = amount;
        this.status = CreditStatus.APPROVED;
    }

    public void reject(String reason) {
        if (!CreditStatus.PENDING.equals(this.status))
            throw new IllegalStateException("So e possivel rejeitar creditos com status PENDING");
        this.status = CreditStatus.REJECTED;
        this.rejectionReason = reason;
        this.approvedAmount = BigDecimal.ZERO;
    }

    public boolean isApproved() { return CreditStatus.APPROVED.equals(this.status); }
    public String getId() { return id; }
    public String getCustomerId() { return customerId; }
    public BigDecimal getRequestedAmount() { return requestedAmount; }
    public BigDecimal getApprovedAmount() { return approvedAmount; }
    public CreditStatus getStatus() { return status; }
    public String getRejectionReason() { return rejectionReason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
