package com.bank.credits.api;

import com.bank.credits.api.dto.CreditRequestDTO;
import com.bank.credits.api.dto.CreditResponse;
import com.bank.credits.application.CreditService;
import com.bank.credits.domain.Credit;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/credits")
public class CreditController {

    private final CreditService creditService;
    public CreditController(CreditService creditService) { this.creditService = creditService; }

    @PostMapping
    public ResponseEntity<CreditResponse> requestCredit(@RequestBody @Valid CreditRequestDTO req) {
        Credit credit = creditService.requestCredit(req.customerId(), req.amount());
        return ResponseEntity.status(HttpStatus.CREATED).body(CreditResponse.from(credit));
    }

    @GetMapping("/{id}")
    public ResponseEntity<CreditResponse> findById(@PathVariable String id) {
        return creditService.findById(id).map(CreditResponse::from).map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/customer/{customerId}")
    public ResponseEntity<List<CreditResponse>> findByCustomer(@PathVariable String customerId) {
        return ResponseEntity.ok(creditService.findByCustomer(customerId).stream()
            .map(CreditResponse::from).toList());
    }
}
