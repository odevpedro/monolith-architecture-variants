package com.bank.credits.infrastructure.clients;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import java.util.Map;

/**
 * Cliente HTTP sem resiliencia.
 *
 * Problemas:
 * - Sem timeout: pode travar indefinidamente
 * - Sem retry: falha transiente derruba a operacao
 * - Sem circuit breaker: se customer-service cair, credit-service cai junto
 */
@Component
public class CustomerServiceClient {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${services.customer.url:http://customer-service:8081}")
    private String customerServiceUrl;

    @SuppressWarnings("unchecked")
    public Map<String, Object> getCustomer(String customerId) {
        return restTemplate.getForObject(
            customerServiceUrl + "/customers/" + customerId, Map.class);
    }
}
