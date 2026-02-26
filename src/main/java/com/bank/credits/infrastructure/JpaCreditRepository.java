package com.bank.credits.infrastructure;

import com.bank.credits.domain.Credit;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface JpaCreditRepository extends JpaRepository<Credit, String> {
    List<Credit> findByCustomerIdOrderByCreatedAtDesc(String customerId);
}
