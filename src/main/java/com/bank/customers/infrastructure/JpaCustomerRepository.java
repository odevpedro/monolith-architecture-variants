package com.bank.customers.infrastructure;

import com.bank.customers.domain.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface JpaCustomerRepository extends JpaRepository<Customer, String> {
    Optional<Customer> findByDocument(String document);
}
