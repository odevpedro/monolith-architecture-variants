package com.bank.customers.application;

import com.bank.customers.domain.Customer;
import com.bank.customers.infrastructure.JpaCustomerRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Optional;

/**
 * Interface publica do modulo customers.
 * Outros modulos acessam clientes SOMENTE atraves desta classe.
 * Nunca acessam JpaCustomerRepository diretamente.
 */
@Service
@Transactional(readOnly = true)
public class CustomerService {
    private final JpaCustomerRepository repo;
    public CustomerService(JpaCustomerRepository repo) { this.repo = repo; }
    public Optional<Customer> findById(String id) { return repo.findById(id); }
}
