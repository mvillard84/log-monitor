# 🛠️ Monitoreo de Logs con AWS Lambda y Notificación a Slack (Terraform)

Este proyecto implementa una solución completa para monitorear errores en los logs de AWS CloudWatch utilizando una función Lambda desarrollada en Python y desplegada con Terraform. Ante la detección de una línea que contenga `"ERROR"`, la función envía una alerta a un canal de Slack.

---

## 📦 Estructura del Proyecto

.
|-- lambda_source/
|   `-- log-monitor.py           # Código fuente de la Lambda
|-- lambda_layer_requests.zip    # Paquete con la librería requests (para Slack)
|-- lambda.zip                   # Código zippeado de la Lambda
|-- main.tf                      # Infraestructura en Terraform
|-- variables.tf                 # Variables definidas
|-- terraform.tfvars             # Valores concretos de las variables
`-- README.md                    # Este archivo

---

## ⚙️ Componentes Desplegados

- **Lambda** Python 3.12 que analiza logs y notifica a Slack.
- **CloudWatch Log Group** donde se escriben los logs de Lambda.
- **Log Subscription Filter** que activa la Lambda si aparece `"ERROR"` en los logs.
- **Metric Filter** que transforma los errores en métricas personalizadas.
- **CloudWatch Alarm** que se activa ante errores frecuentes.
- **Lambda Layer** con `requests` para enviar mensajes a Slack.
- **Permisos IAM** necesarios para que Lambda lea logs y escriba en CloudWatch.

---
