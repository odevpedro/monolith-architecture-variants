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
