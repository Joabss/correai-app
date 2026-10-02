# CorreAI App

App Flutter (Android) para a [correai-api](../correai-api): registro de corridas e caminhadas, histórico, resumo, evolução semanal e metas.

## Funcionalidades

- Login anônimo automático: o app chama `POST /auth/anonymous` na primeira abertura e guarda o JWT (`shared_preferences`).
- **Início**: resumo (semana, mês, sequência, maior distância) e gráfico de evolução das últimas 8 semanas.
- **Histórico**: lista paginada com rolagem infinita, atualização por arrastar e remoção de atividades.
- **Gravar**: cronômetro com GPS (iniciar, pausar, retomar, finalizar). Calcula distância e pace em tempo real, ignora leituras imprecisas (>30 m) e o intervalo em pausa, e roda em segundo plano com notificação. Ao finalizar, escolha o tipo e salve.
- **Manual**: registro sem GPS: tipo, distância, duração (`mm:ss` ou `h:mm:ss`), tipo de treino, esforço e notas.
- **Metas**: distância, atividades e pace médio (semanal ou mensal), com progresso e remoção.

## Como rodar no celular

1. Suba a API (`./mvnw spring-boot:run` na correai-api). O celular e o PC precisam estar na mesma rede Wi-Fi e a porta 8080 liberada no firewall.
2. Descubra o IP do PC (`hostname -I`) e rode:

```bash
flutter run --dart-define=API_BASE_URL=http://<IP_DO_PC>:8080
```

O valor padrão está em `lib/core/config.dart`. O app permite HTTP sem TLS (`usesCleartextTraffic`) para desenvolvimento; use HTTPS em produção e remova essa flag.

Na primeira gravação o Android pede permissão de localização (escolha "Durante o uso do app") e de notificações.

## Estrutura

```
lib/
  core/       cliente HTTP, repositório, estado compartilhado, formatação
  models/     modelos da API
  features/   home, history, track (GPS), register, goals
```

## Qualidade

```bash
flutter analyze
flutter test
```

## Próximos passos

- Mapa e trajeto da corrida (hoje só distância e tempo são guardados).
- Planejamento de treinos e badges (quando a API tiver esses recursos).
- Refresh token ou cadastro por e-mail para não perder dados ao trocar de aparelho.
