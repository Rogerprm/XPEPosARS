# XPEPosARS
Repositório para armazenar os documentos do projeto da pós graduação em arquitetura de Software e Soluções da faculdade XPE.


# Documentação tecnica da solução

## Visão Geral da Arquitetura
Esta solução utiliza uma arquitetura baseada em microservices, com componentes gerenciados pela AWS. O objetivo principal é garantir escalabilidade, desacoplamento de serviços e otimização de processos de integração e processamento de dados (planilhas XLS). A solução foi projetada para ser flexível, com integração de dados em tempo real entre os serviços e um mecanismo de processamento batch eficiente para grandes volumes de dados.

A arquitetura consiste em dois principais sistemas integrados:

1. Sistema de Microservices e Integração AWS
2. Sistema de Processamento com AWS Batch


1. Especificação dos Componentes da Arquitetura
- API Gateway
Função: Atua como ponto de entrada para todas as requisições HTTP/HTTPS feitas para os microservices.
Autenticação: Integrado ao Amazon Cognito para autenticação e autorização de usuários por meio de tokens JWT, garantindo acesso seguro às APIs.
Escalabilidade: Capacidade de escalar automaticamente de acordo com o volume de requisições.
- ALB (Application Load Balancer)
Função: Distribui as requisições recebidas pelo API Gateway entre os containers rodando no ECS.
Configurações Técnicas:
Listeners: Configurações específicas de HTTP/HTTPS.
Target Groups: Roteia requisições para os containers baseados na saúde e na carga de trabalho.
Escalonamento Automático: Adapta-se ao aumento ou diminuição de tráfego ajustando a quantidade de instâncias ECS.
- ECS (Elastic Container Service)
Função: Plataforma de orquestração de containers onde os microservices estão hospedados.
Configuração:
Cluster: Agrupamento de containers Docker executando diferentes APIs.
Serviços e Tasks: Cada API roda como um serviço separado no ECS, com tarefas configuradas para escalar automaticamente.
Microservices Implementados:
SalesAPI: Processa vendas e notifica o sistema de estoque via SQS.
FinanceAPI: Gerencia transações financeiras e interage com ReportingAPI via eventos.
InventoryAPI: Escuta eventos do SQS para manter o estoque atualizado com base nas vendas.
HRAPI: Gerencia informações dos funcionários e integração com RDS.
- SQS (Simple Queue Service)
Função: Comunicação assíncrona entre os microservices, garantindo desacoplamento e confiabilidade no processamento de dados.
Filas Configuradas:
Sales-Inventory: Notifica mudanças no estoque após cada venda.
Finance-Reporting: Notifica o sistema de relatórios após eventos financeiros.
Processamento Assíncrono: Permite que os serviços troquem informações sem dependência direta de tempo de execução.
- Cognito
Função: Provedor de identidade, gerenciando autenticação e autorização.
Segurança: Usa tokens de segurança (JWT) para validação no API Gateway, fornecendo segurança em cada requisição.
- RDS (Relational Database Service)
Função: Banco de dados relacional que armazena dados de vendas, inventário, finanças e recursos humanos.
Configuração:
Multi-AZ: Alta disponibilidade com failover automático entre regiões da AWS.
Backups Automáticos: Snapshots periódicos para garantir recuperação de dados.
Integrações: APIs acessam diretamente o RDS para gravar e ler dados transacionais.
- S3 (Simple Storage Service)
Função: Armazenamento de relatórios e arquivos estáticos processados, incluindo planilhas XLS carregadas via AWS Batch.
Criptografia: Armazenamento seguro com criptografia no lado do servidor (SSE-S3).
Integrações: AWS Batch faz upload dos arquivosprocessados diretamente no S3 para consulta posterior.

2. Fluxo de Dados e Integrações
- Fluxo Principal de Microservices
O usuário acessa o sistema via API Gateway.
O API Gateway autentica o usuário usando o Cognito e encaminha a requisição para o ALB.
O ALB distribui a requisição para o microservice apropriado dentro do ECS:
SalesAPI: Recebe requisições de vendas e dispara mensagens via SQS para atualizar o InventoryAPI.
FinanceAPI: Gerencia transações financeiras e gera eventos para o ReportingAPI.
Os dados processados são armazenados no RDS.
Relatórios e arquivos processados são armazenados no S3 para consulta futura.
- Fluxo de Processamento com AWS Batch
O FTP envia arquivos XLS para a AWS, que são processados pelo AWS Batch.
O AWS Batch executa jobs de processamento (scripts Python) para transformar os dados.
Os dados são carregados no RDS, e os arquivos originais ou processados são armazenados no S3.

3. Provisionamento com Terraform
- Vantagens de Usar Terraform
Infraestrutura como Código: O Terraform permite que a infraestrutura seja descrita e gerenciada como código, facilitando a automação e a reprodução dos ambientes.
Modularidade: Cada serviço AWS é definido em um módulo separado, o que facilita a manutenção e a escalabilidade do ambiente.
Versionamento e Controle: O uso de arquivos de estado no S3 permite rastrear mudanças na infraestrutura e garantir consistência entre ambientes.

4. Desenho detalhado com o C4 Nivel 3

![](/src/images/jpg/c4n3-2.png)