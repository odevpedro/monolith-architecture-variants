package com.bank.notifications.application;

import com.bank.credits.domain.Credit;

/**
 * Interface publica do modulo notifications.
 * CreditService depende desta interface, nao da implementacao.
 * Permite trocar EmailAdapter por SMS/Push sem tocar no CreditService.
 */
public interface NotificationService {
    void notifyCreditResult(String email, Credit credit);
}
