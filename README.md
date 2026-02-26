# Monolito Tradicional



## Divisão do Repositório

Esse repositório é divido em branches: tradicional, modular & distribuida. Para exemplificar o uso do monolito em cada um desses contextos.

## Contexto

Este exemplo demonstra um monolito tradicional, onde não existem fronteiras claras entre camadas ou domínios.

Regra de negócio, acesso a banco e integração externa coexistem dentro das mesmas classes.

O objetivo desta implementação é evidenciar como sistemas legados normalmente surgem.

---

## Características

- Controller contém regra de negócio
- SQL direto espalhado pelo código
- Dependência direta de infraestrutura
- Baixa testabilidade
- Alto acoplamento interno

---

## Exemplo

### CreditController.java

```java
@RestController
@RequestMapping("/credits")
public class CreditController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private JavaMailSender mailSender;

    @PostMapping("/request")
    public ResponseEntity<String> requestCredit(@RequestBody Map<String, Object> payload) {

        String customerId = (String) payload.get("customerId");
        Double amount = (Double) payload.get("amount");

        if (amount <= 0 || amount > 50000) {
            return ResponseEntity.badRequest().body("Valor inválido");
        }

        Integer creditScore = jdbcTemplate.queryForObject(
            "SELECT score FROM customers WHERE id = ?",
            Integer.class,
            customerId
        );

        // lógica de aprovação + persistência + envio de email tudo aqui

        return ResponseEntity.ok("Processado");
    }
}
```

---

## Problemas Estruturais

- Violação do Single Responsibility Principle
- Dependência direta de infraestrutura
- Mudança de regra exige alterar camada de apresentação
- Código difícil de testar isoladamente
- Alto risco de virar legado

---

## Quando aparece

- Projetos iniciados sem arquitetura
- Sistemas que cresceram organicamente
- Pressão por entrega sem preocupação estrutural
