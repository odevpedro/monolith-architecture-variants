# ADR 001 - Monolito Modular como arquitetura base

**Status:** Aceito

## Contexto
Sistema de credito com tres contextos: clientes, creditos e notificacoes.

## Decisao
Monolito Modular.

## Justificativa
- Tradicional: acoplamento invisivel vira legado
- Microsservicos agora: dominio em compreensao, fronteiras erradas sao caras
- Modular: fronteiras explicitas sem complexidade operacional

## Quando revisitar
- Times diferentes precisarem de deploys independentes
- Volume exigir escala independente entre modulos
