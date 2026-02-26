package com.bank.credits.api;

import jakarta.annotation.Resource;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

/**
 * MONOLITO TRADICIONAL - anti-pattern intencional para fins didaticos.
 *
 * Problemas:
 * [1] SQL direto no controller - mudanca no schema quebra logica de negocio
 * [2] Regra de negocio no controller - impossivel reutilizar sem duplicar
 * [3] Envio de e-mail no controller - impossivel testar sem SMTP real
 * [4] Dominio exposto na resposta - mudanca interna vira breaking change na API
 *
 * Compare com a branch main para ver como resolver cada problema.
 */
@RestController
@RequestMapping("/api/credits")
public class CreditController {

    @Resource private JdbcTemplate jdbcTemplate; // [1]
    @Resource private JavaMailSender mailSender;  // [3]

    @PostMapping
    public ResponseEntity<String> requestCredit(@RequestBody Map<String, Object> payload) {
        String customerId = (String) payload.get("customerId");
        Double amount = (Double) payload.get("amount");

        if (amount == null || amount <= 0 || amount > 50000) // [2]
            return ResponseEntity.badRequest().body("Valor invalido");

        Map<String, Object> customer;
        try {
            customer = jdbcTemplate.queryForMap( // [1]
                "SELECT credit_score, email FROM customers WHERE id = ?", customerId);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Cliente nao encontrado");
        }

        int creditScore = ((Number) customer.get("credit_score")).intValue();
        String email = (String) customer.get("email");

        // [2] Regra de negocio inline no controller
        String status;
        double approvedAmount;
        if (creditScore >= 700)      { status = "APPROVED"; approvedAmount = amount; }
        else if (creditScore >= 500) { status = "APPROVED"; approvedAmount = amount * 0.5; }
        else                         { status = "REJECTED"; approvedAmount = 0.0; }

        jdbcTemplate.update( // [1]
            "INSERT INTO credits (customer_id, requested_amount, approved_amount, status, created_at) VALUES (?, ?, ?, ?, NOW())",
            customerId, amount, approvedAmount, status);

        try {
            SimpleMailMessage msg = new SimpleMailMessage(); // [3]
            msg.setTo(email);
            msg.setSubject("Resultado da solicitacao de credito");
            msg.setText("Status: " + status + ". Aprovado: R$" + approvedAmount);
            mailSender.send(msg);
        } catch (Exception e) {
            System.out.println("Falha ao enviar e-mail: " + e.getMessage()); // silencia o erro
        }

        return ResponseEntity.ok("Status: " + status + ". Aprovado: R$" + approvedAmount); // [4]
    }

    @GetMapping("/customer/{customerId}")
    public ResponseEntity<List<Map<String, Object>>> getHistory(@PathVariable String customerId) {
        return ResponseEntity.ok(jdbcTemplate.queryForList( // [1] + [4]
            "SELECT * FROM credits WHERE customer_id = ? ORDER BY created_at DESC", customerId));
    }
}
