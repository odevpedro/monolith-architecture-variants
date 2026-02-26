# Monolito Distribuído

## Contexto

Este exemplo demonstra um anti-pattern conhecido como monolito distribuído.

Apesar de existir separação em múltiplos serviços, o acoplamento estrutural permanece elevado.

O resultado é alta complexidade operacional com baixa autonomia real.

---

## Características

- Múltiplos serviços
- Chamadas síncronas encadeadas
- Banco compartilhado
- Acoplamento temporal
- Falhas em cascata

---

## Exemplo

### CreditService.java

```java
@Service
public class CreditService {

    private final CustomerServiceClient customerClient;
    private final ScoreServiceClient scoreClient;
    private final ComplianceServiceClient complianceClient;
    private final NotificationServiceClient notificationClient;

    public CreditResponse requestCredit(String customerId, BigDecimal amount) {

        CustomerDTO customer = customerClient.getCustomer(customerId);
        ScoreDTO score = scoreClient.getScore(customerId);
        ComplianceDTO compliance = complianceClient.checkCompliance(customerId);

        if (score.getValue() < 500 || !compliance.isApproved()) {
            return CreditResponse.rejected();
        }

        CreditRequest saved = creditRepository.save(new CreditRequest(customerId, amount));

        notificationClient.sendApprovalEmail(customer.getEmail(), saved.getId());

        return CreditResponse.from(saved);
    }
}
```

---

## Problemas Estruturais

- Latência acumulada
- Deploy teoricamente independente, mas contrato acoplado
- Banco compartilhado elimina autonomia
- Complexidade operacional elevada
- Sistema frágil

---

## Quando surge

- Migração mal planejada para microsserviços
- Separação prematura de deploy
- Ausência de design orientado a domínio
