package com.bank.credits.api;

import com.bank.credits.application.CreditService;
import com.bank.credits.domain.Credit;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.Map;

@RestController
@RequestMapping("/api/credits")
public class CreditController {

    private final CreditService creditService;
    public CreditController(CreditService creditService) { this.creditService = creditService; }

    @PostMapping
    public ResponseEntity<Map<String, Object>> requestCredit(@RequestBody Map<String, Object> payload) {
        String customerId = (String) payload.get("customerId");
        BigDecimal amount = new BigDecimal(payload.get("amount").toString());
        Credit credit = creditService.requestCredit(customerId, amount);
        return ResponseEntity.ok(Map.of(
            "id", credit.getId(),
            "status", credit.getStatus().name(),
            "approvedAmount", credit.getApprovedAmount()
        ));
    }
}
