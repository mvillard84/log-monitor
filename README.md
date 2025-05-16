# 🛠️ Monitoreo de Logs con AWS Lambda y Notificación a Slack gestionado con Terraform

Este proyecto implementa una solución completa para monitorear errores en los logs de AWS CloudWatch utilizando una función Lambda desarrollada en Python y desplegada con Terraform. Ante la detección de una línea que contenga `"ERROR"`, la función envía una alerta a un canal de Slack.

---

## 📦 Estructura del Proyecto

```
.
├── lambda_source/
│   └── log-monitor.py            # Código fuente de la Lambda
├── lambda_layer_requests.zip     # Paquete con la librería requests (para Slack)
├── lambda.zip                    # Código zippeado de la Lambda
├── main.tf                       # Infraestructura en Terraform
├── variables.tf                  # Variables definidas
├── terraform.tfvars              # Valores concretos de las variables
└── README.md                     # Este archivo
```

## ⚙️ Componentes Desplegados

- **Lambda** en Python 3.12 que analiza logs y notifica a Slack.
- **CloudWatch Log Group** donde se escriben los logs de Lambda.
- **Log Subscription Filter** que activa la Lambda si aparece `"ERROR"` en los logs.
- **IAM Role** con permisos para:
  - Escribir logs en CloudWatch.
  - Ser invocada por CloudWatch Logs.
- **Lambda Layer** que incluye la librería `requests`.

---

## 🧪 Cómo generar el archivo `lambda_layer_requests.zip`

Este archivo contiene la librería `requests` empaquetada como capa para Lambda.

```bash
mkdir -p python
pip install requests -t python
zip -r lambda_layer_requests.zip python
rm -rf python
```
---

## ⚙️ Ciclo de vida del servicio

Inicializar Terraform (descarga providers, prepara backend)
```bash
terraform init
```

Mostrar el plan de ejecución (qué va a crear/modificar/eliminar)
```bash
terraform plan
```
Aplicar la infraestructura (crear/modificar recursos)
```bash
terraform apply
```

Destruir toda la infraestructura creada
```bash
terraform destroy
```
