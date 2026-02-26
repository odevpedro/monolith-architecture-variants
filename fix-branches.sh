
#!/bin/bash
# fix-branches.sh
# Corrige o conteudo das branches modular e distributed
# Execute DENTRO da pasta do repositorio clonado:
#   git clone https://github.com/odevpedro/monolith-architecture-variants
#   cd monolith-architecture-variants
#   chmod +x fix-branches.sh && ./fix-branches.sh

set -e

BASE="src/main/java/com/bank"

echo "Detectando branches..."
git fetch --all

BRANCHES=$(git branch -a | sed 's/remotes\/origin\///' | sed 's/\*//' | tr -d ' ' | sort -u)
echo "Branches encontradas: $BRANCHES"

# Detecta nomes reais das branches
MODULAR_BRANCH=$(echo "$BRANCHES" | grep -i "modular" | head -1)
DISTRIBUTED_BRANCH=$(echo "$BRANCHES" | grep -i "distribut" | head -1)
TRADITIONAL_BRANCH=$(echo "$BRANCHES" | grep -i "traditional\|tradicional" | head -1)

echo "Branch tradicional : $TRADITIONAL_BRANCH"
echo "Branch modular     : $MODULAR_BRANCH"
echo "Branch distributed : $DISTRIBUTED_BRANCH"

if [ -z "$MODULAR_BRANCH" ] || [ -z "$DISTRIBUTED_BRANCH" ]; then
  echo "Erro: nao foi possivel detectar as branches. Verifique os nomes e tente novamente."
  exit 1
fi

# ============================================================
# FUNCAO: aplica os arquivos do monolito MODULAR
# ============================================================
apply_modular() {
  echo "Aplicando codigo do monolito modular..."

  mkdir -p $BASE/credits/{api/dto,application/rules,domain,infrastructure}
  mkdir -p $BASE/customers/{application,domain,infrastructure}
  mkdir -p $BASE/notifications/{application,infrastructure}

  # --- Customer domain ---
  cat > $BASE/customers/domain/Customer.java << 'EOF'
package com.bank.customers.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "customers")
public class Customer {

    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    @Column(nullable = false, unique = true) private String document;
    @Column(nullable = false) private String fullName;
    @Column(nullable = false, unique = true) private String email;
    @Column(nullable = false) private Integer creditScore;
    @Column(nullable = false, precision = 15, scale = 2) private BigDecimal creditLimit;

    protected Customer() {}

    public String getId() { return id; }
    public String getDocument() { return document; }
    public String getFullName() { return fullName; }
    public String getEmail() { return email; }
    public Integer getCreditScore() { return creditScore; }
    public BigDecimal getCreditLimit() { return creditLimit; }
}
EOF

  cat > $BASE/customers/infrastructure/JpaCustomerRepository.java << 'EOF'
package com.bank.customers.infrastructure;

import com.bank.customers.domain.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface JpaCustomerRepository extends JpaRepository<Customer, String> {
    Optional<Customer> findByDocument(String document);
}
EOF

  cat > $BASE/customers/application/CustomerService.java << 'EOF'
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
EOF

  # --- Notifications ---
  cat > $BASE/notifications/application/NotificationService.java << 'EOF'
package com.bank.notifications.application;

import com.bank.credits.domain.Credit;

/**
 * Interface publica do modulo notifications.
 * CreditService depende desta interface, nao da implementacao concreta.
 * Permite trocar Email por SMS/Push sem tocar no CreditService.
 */
public interface NotificationService {
    void notifyCreditResult(String email, Credit credit);
}
EOF

  cat > $BASE/notifications/infrastructure/EmailNotificationAdapter.java << 'EOF'
package com.bank.notifications.infrastructure;

import com.bank.credits.domain.Credit;
import com.bank.notifications.application.NotificationService;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailNotificationAdapter implements NotificationService {

    private final JavaMailSender mailSender;
    public EmailNotificationAdapter(JavaMailSender mailSender) { this.mailSender = mailSender; }

    @Override
    public void notifyCreditResult(String email, Credit credit) {
        SimpleMailMessage msg = new SimpleMailMessage();
        msg.setTo(email);
        msg.setSubject("Resultado da sua solicitacao de credito");
        msg.setText(credit.isApproved()
            ? String.format("Credito de R$ %.2f aprovado.", credit.getApprovedAmount())
            : "Solicitacao reprovada. Motivo: " + credit.getRejectionReason());
        mailSender.send(msg);
    }
}
EOF

  # --- Credits domain ---
  cat > $BASE/credits/domain/CreditStatus.java << 'EOF'
package com.bank.credits.domain;
public enum CreditStatus { PENDING, APPROVED, REJECTED }
EOF

  cat > $BASE/credits/domain/CreditDecision.java << 'EOF'
package com.bank.credits.domain;

import java.math.BigDecimal;

public class CreditDecision {
    private final boolean approved;
    private final BigDecimal approvedAmount;
    private final String rejectionReason;

    private CreditDecision(boolean approved, BigDecimal approvedAmount, String rejectionReason) {
        this.approved = approved;
        this.approvedAmount = approvedAmount;
        this.rejectionReason = rejectionReason;
    }

    public static CreditDecision approved(BigDecimal amount) {
        return new CreditDecision(true, amount, null);
    }
    public static CreditDecision rejected(String reason) {
        return new CreditDecision(false, BigDecimal.ZERO, reason);
    }

    public boolean isApproved() { return approved; }
    public BigDecimal getApprovedAmount() { return approvedAmount; }
    public String getRejectionReason() { return rejectionReason; }
}
EOF

  cat > $BASE/credits/domain/Credit.java << 'EOF'
package com.bank.credits.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "credits")
public class Credit {

    @Id @GeneratedValue(strategy = GenerationType.UUID) private String id;
    @Column(nullable = false) private String customerId;
    @Column(nullable = false, precision = 15, scale = 2) private BigDecimal requestedAmount;
    @Column(precision = 15, scale = 2) private BigDecimal approvedAmount;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private CreditStatus status;
    private String rejectionReason;
    @Column(nullable = false) private LocalDateTime createdAt;

    protected Credit() {}

    public static Credit create(String customerId, BigDecimal requestedAmount) {
        Credit c = new Credit();
        c.customerId = customerId;
        c.requestedAmount = requestedAmount;
        c.status = CreditStatus.PENDING;
        c.createdAt = LocalDateTime.now();
        return c;
    }

    public void approve(BigDecimal amount) {
        if (!CreditStatus.PENDING.equals(this.status))
            throw new IllegalStateException("So e possivel aprovar creditos com status PENDING");
        this.approvedAmount = amount;
        this.status = CreditStatus.APPROVED;
    }

    public void reject(String reason) {
        if (!CreditStatus.PENDING.equals(this.status))
            throw new IllegalStateException("So e possivel rejeitar creditos com status PENDING");
        this.status = CreditStatus.REJECTED;
        this.rejectionReason = reason;
        this.approvedAmount = BigDecimal.ZERO;
    }

    public boolean isApproved() { return CreditStatus.APPROVED.equals(this.status); }
    public String getId() { return id; }
    public String getCustomerId() { return customerId; }
    public BigDecimal getRequestedAmount() { return requestedAmount; }
    public BigDecimal getApprovedAmount() { return approvedAmount; }
    public CreditStatus getStatus() { return status; }
    public String getRejectionReason() { return rejectionReason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
EOF

  # --- Credits rules ---
  cat > $BASE/credits/application/rules/CreditEvaluator.java << 'EOF'
package com.bank.credits.application.rules;

import com.bank.credits.domain.CreditDecision;
import com.bank.customers.domain.Customer;
import org.springframework.stereotype.Component;
import java.math.BigDecimal;

/**
 * Regra de negocio isolada.
 * Testavel sem Spring, sem banco, sem HTTP.
 * Qualquer mudanca na regra de aprovacao acontece AQUI e SOMENTE AQUI.
 */
@Component
public class CreditEvaluator {
    private static final int MIN_SCORE_FULL = 700;
    private static final int MIN_SCORE_PARTIAL = 500;
    private static final BigDecimal PARTIAL_FACTOR = new BigDecimal("0.5");

    public CreditDecision evaluate(Customer customer, BigDecimal requestedAmount) {
        int score = customer.getCreditScore();
        if (score >= MIN_SCORE_FULL) return CreditDecision.approved(requestedAmount);
        if (score >= MIN_SCORE_PARTIAL) return CreditDecision.approved(requestedAmount.multiply(PARTIAL_FACTOR));
        return CreditDecision.rejected("Score " + score + " abaixo do minimo de " + MIN_SCORE_PARTIAL);
    }
}
EOF

  # --- Credits application ---
  cat > $BASE/credits/application/CreditService.java << 'EOF'
package com.bank.credits.application;

import com.bank.credits.application.rules.CreditEvaluator;
import com.bank.credits.domain.Credit;
import com.bank.credits.domain.CreditDecision;
import com.bank.credits.infrastructure.JpaCreditRepository;
import com.bank.customers.application.CustomerService;
import com.bank.customers.domain.Customer;
import com.bank.notifications.application.NotificationService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class CreditService {

    private final JpaCreditRepository creditRepository;
    private final CustomerService customerService;         // interface publica do modulo customers
    private final CreditEvaluator creditEvaluator;
    private final NotificationService notificationService; // interface publica do modulo notifications

    public CreditService(JpaCreditRepository creditRepository, CustomerService customerService,
                         CreditEvaluator creditEvaluator, NotificationService notificationService) {
        this.creditRepository = creditRepository;
        this.customerService = customerService;
        this.creditEvaluator = creditEvaluator;
        this.notificationService = notificationService;
    }

    public Credit requestCredit(String customerId, BigDecimal amount) {
        // Acessa customers pela interface publica — nunca pelo JpaCustomerRepository diretamente
        Customer customer = customerService.findById(customerId)
            .orElseThrow(() -> new RuntimeException("Cliente nao encontrado: " + customerId));

        CreditDecision decision = creditEvaluator.evaluate(customer, amount);
        Credit credit = Credit.create(customerId, amount);

        if (decision.isApproved()) credit.approve(decision.getApprovedAmount());
        else credit.reject(decision.getRejectionReason());

        Credit saved = creditRepository.save(credit);
        notificationService.notifyCreditResult(customer.getEmail(), saved);
        return saved;
    }

    @Transactional(readOnly = true)
    public Optional<Credit> findById(String id) { return creditRepository.findById(id); }

    @Transactional(readOnly = true)
    public List<Credit> findByCustomer(String customerId) {
        return creditRepository.findByCustomerIdOrderByCreatedAtDesc(customerId);
    }
}
EOF

  # --- Credits infrastructure ---
  cat > $BASE/credits/infrastructure/JpaCreditRepository.java << 'EOF'
package com.bank.credits.infrastructure;

import com.bank.credits.domain.Credit;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface JpaCreditRepository extends JpaRepository<Credit, String> {
    List<Credit> findByCustomerIdOrderByCreatedAtDesc(String customerId);
}
EOF

  # --- Credits API ---
  cat > $BASE/credits/api/dto/CreditRequestDTO.java << 'EOF'
package com.bank.credits.api.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record CreditRequestDTO(
    @NotBlank(message = "customerId e obrigatorio") String customerId,
    @NotNull @DecimalMin("100.00") @DecimalMax("50000.00") BigDecimal amount
) {}
EOF

  cat > $BASE/credits/api/dto/CreditResponse.java << 'EOF'
package com.bank.credits.api.dto;

import com.bank.credits.domain.Credit;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public record CreditResponse(
    String id, String customerId,
    BigDecimal requestedAmount, BigDecimal approvedAmount,
    String status, LocalDateTime createdAt
) {
    public static CreditResponse from(Credit c) {
        return new CreditResponse(c.getId(), c.getCustomerId(),
            c.getRequestedAmount(), c.getApprovedAmount(),
            c.getStatus().name(), c.getCreatedAt());
    }
}
EOF

  cat > $BASE/credits/api/CreditController.java << 'EOF'
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
EOF
}

# ============================================================
# FUNCAO: aplica os arquivos do monolito DISTRIBUTED
# ============================================================
apply_distributed() {
  echo "Aplicando codigo do monolito distribuido..."

  mkdir -p $BASE/credits/infrastructure/clients

  # --- Clients ---
  cat > $BASE/credits/infrastructure/clients/CustomerServiceClient.java << 'EOF'
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
EOF

  cat > $BASE/credits/infrastructure/clients/NotificationServiceClient.java << 'EOF'
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
EOF

  # --- CreditService distribuido ---
  cat > $BASE/credits/application/CreditService.java << 'EOF'
package com.bank.credits.application;

import com.bank.credits.domain.Credit;
import com.bank.credits.domain.CreditDecision;
import com.bank.credits.infrastructure.JpaCreditRepository;
import com.bank.credits.infrastructure.clients.CustomerServiceClient;
import com.bank.credits.infrastructure.clients.NotificationServiceClient;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.Map;

/**
 * MONOLITO DISTRIBUIDO - cadeia sincrona de chamadas HTTP.
 *
 * Latencia acumulada por operacao:
 *   customerClient.getCustomer()          ~200ms
 *   jdbcTemplate (banco compartilhado)     ~50ms
 *   notificationClient.sendCreditResult() ~100ms
 *   Total minimo:                         ~350ms
 *
 * Se qualquer chamada falhar: 500 Error + possivel estado inconsistente.
 */
@Service
@Transactional
public class CreditService {

    private final JpaCreditRepository creditRepository;
    private final CustomerServiceClient customerClient;
    private final NotificationServiceClient notificationClient;
    private final JdbcTemplate jdbcTemplate; // banco compartilhado entre "servicos"

    public CreditService(JpaCreditRepository creditRepository,
                         CustomerServiceClient customerClient,
                         NotificationServiceClient notificationClient,
                         JdbcTemplate jdbcTemplate) {
        this.creditRepository = creditRepository;
        this.customerClient = customerClient;
        this.notificationClient = notificationClient;
        this.jdbcTemplate = jdbcTemplate;
    }

    public Credit requestCredit(String customerId, BigDecimal amount) {

        // Chamada HTTP 1 - trava se customer-service estiver lento
        Map<String, Object> customer = customerClient.getCustomer(customerId);
        int creditScore = ((Number) customer.get("creditScore")).intValue();
        String email = (String) customer.get("email");

        // Acessa banco compartilhado - dois "servicos" no mesmo schema
        Integer activeCredits = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM credits WHERE customer_id = ? AND status = 'APPROVED'",
            Integer.class, customerId);

        CreditDecision decision;
        if (creditScore >= 700 && activeCredits < 3)
            decision = CreditDecision.approved(amount);
        else if (creditScore >= 500 && activeCredits < 2)
            decision = CreditDecision.approved(amount.multiply(new BigDecimal("0.5")));
        else
            decision = CreditDecision.rejected("Score insuficiente ou limite de creditos atingido");

        Credit credit = Credit.create(customerId, amount);
        if (decision.isApproved()) credit.approve(decision.getApprovedAmount());
        else credit.reject(decision.getRejectionReason());

        Credit saved = creditRepository.save(credit); // credito salvo no banco

        // Chamada HTTP 2 - se cair aqui: credito salvo + API retorna 500
        notificationClient.sendCreditResult(email, saved.getId(), saved.getStatus().name());

        return saved;
    }
}
EOF

  # --- CreditController distribuido (sem validacao, aceita Map) ---
  cat > $BASE/credits/api/CreditController.java << 'EOF'
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
EOF

  # Garante que o JpaCreditRepository existe
  mkdir -p $BASE/credits/infrastructure
  cat > $BASE/credits/infrastructure/JpaCreditRepository.java << 'EOF'
package com.bank.credits.infrastructure;

import com.bank.credits.domain.Credit;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface JpaCreditRepository extends JpaRepository<Credit, String> {
    List<Credit> findByCustomerIdOrderByCreatedAtDesc(String customerId);
}
EOF

  # CreditDecision necessario para compilar
  mkdir -p $BASE/credits/domain
  cat > $BASE/credits/domain/CreditDecision.java << 'EOF'
package com.bank.credits.domain;

import java.math.BigDecimal;

public class CreditDecision {
    private final boolean approved;
    private final BigDecimal approvedAmount;
    private final String rejectionReason;

    private CreditDecision(boolean approved, BigDecimal approvedAmount, String rejectionReason) {
        this.approved = approved;
        this.approvedAmount = approvedAmount;
        this.rejectionReason = rejectionReason;
    }

    public static CreditDecision approved(BigDecimal amount) {
        return new CreditDecision(true, amount, null);
    }
    public static CreditDecision rejected(String reason) {
        return new CreditDecision(false, BigDecimal.ZERO, reason);
    }

    public boolean isApproved() { return approved; }
    public BigDecimal getApprovedAmount() { return approvedAmount; }
    public String getRejectionReason() { return rejectionReason; }
}
EOF
}

# ============================================================
# APLICA MODULAR
# ============================================================
echo ""
echo "==> Corrigindo branch: $MODULAR_BRANCH"
git checkout "$MODULAR_BRANCH"

apply_modular

git add .
git commit -m "feat: monolito modular com fronteiras claras entre modulos

- Modulo credits: dominio rico, regras isoladas, API limpa com DTOs
- Modulo customers: interface publica CustomerService
- Modulo notifications: interface NotificationService substituivel
- CreditEvaluator testavel sem Spring, sem banco, sem HTTP
- CreditService orquestra sem conhecer implementacoes"

# ============================================================
# APLICA DISTRIBUTED
# ============================================================
echo ""
echo "==> Corrigindo branch: $DISTRIBUTED_BRANCH"
git checkout "$DISTRIBUTED_BRANCH"

apply_distributed

git add .
git commit -m "refactor: monolito distribuido com acoplamento sincrono

Anti-pattern intencional para fins didaticos

- Cadeia de chamadas HTTP sincronas por operacao (~350ms minimo)
- Banco de dados compartilhado entre servicos
- Estado inconsistente quando notification-service cai
- Sem circuit breaker, sem retry, sem timeout

Compare com a branch modular para ver a solucao correta"

# ============================================================
# PUSH
# ============================================================
echo ""
echo "==> Fazendo push de todas as branches..."
git push origin "$MODULAR_BRANCH"
git push origin "$DISTRIBUTED_BRANCH"

# Volta para a branch tradicional
git checkout "$TRADITIONAL_BRANCH" 2>/dev/null || git checkout main

echo ""
echo "Concluido! Branches corrigidas e enviadas para o GitHub:"
echo "  - $MODULAR_BRANCH : monolito modular"
echo "  - $DISTRIBUTED_BRANCH: monolito distribuido"
echo ""
echo "Acesse: https://github.com/odevpedro/monolith-architecture-variants"