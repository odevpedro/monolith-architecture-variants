package com.bank.credits.api.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record CreditRequestDTO(
    @NotBlank(message = "customerId e obrigatorio") String customerId,
    @NotNull @DecimalMin("100.00") @DecimalMax("50000.00") BigDecimal amount
) {}
