package com.bank.credits.infrastructure.clients;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import java.util.Map;

/**
 * Se notification-service cair apos o credito ser salvo no banco:
 * - O credito esta committed (nao da rollback)
 * - Este metodo lanca excecao
 * - A API retorna 500 mesmo o credito estando aprovado
 * - Estado inconsistente garantido
 */
@Component
public class NotificationServiceClient {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${services.notification.url:http://notification-service:8083}")
    private String notificationServiceUrl;

    public void sendCreditResult(String email, String creditId, String status) {
        restTemplate.postForObject(
            notificationServiceUrl + "/notifications/credit",
            Map.of("email", email, "creditId", creditId, "status", status),
            Void.class);
    }
}
