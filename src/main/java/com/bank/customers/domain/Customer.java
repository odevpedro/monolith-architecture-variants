package com.bank.customers.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "customers")
public class Customer {

    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    @Column(nullable = false, unique = true) private String document;
    @Column(nullable = false) private String fullName;
    @Column(nullable = false, unique = true) private String email;
    @Column(nullable = false) private Integer creditScore;
    @Column(nullable = false, precision = 15, scale = 2) private BigDecimal creditLimit;

    protected Customer() {}

    public String getId() { return id; }
    public String getDocument() { return document; }
    public String getFullName() { return fullName; }
    public String getEmail() { return email; }
    public Integer getCreditScore() { return creditScore; }
    public BigDecimal getCreditLimit() { return creditLimit; }
}
