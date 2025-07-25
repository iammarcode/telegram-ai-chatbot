# Telegram AI Chatbot

A sophisticated Spring Boot application that provides an AI-powered Telegram bot with ChatGPT integration, featuring message tracking, cloud deployment, and containerized architecture.

## 🚀 Features

- **AI-Powered Conversations**: Integrates with ChatGPT API for intelligent responses
- **Message Tracking**: Counts and tracks keyword usage with persistent storage
- **Multi-Environment Support**: Local development, Docker, and AWS production deployments
- **Secure Configuration**: Environment-based configuration with secrets management
- **Cloud-Native Architecture**: Built for AWS ECS Fargate with auto-scaling capabilities
- **Database Persistence**: MySQL database for message count tracking
- **Comprehensive Logging**: Structured logging with CloudWatch integration

## 🏗️ Architecture

### Application Architecture
- **Framework**: Spring Boot 3.1.7 with Java 17
- **Database**: MySQL 8.0 with JPA/Hibernate
- **Telegram Integration**: Telegram Bots API via `telegrambots-spring-boot-starter`
- **AI Integration**: ChatGPT API with Azure OpenAI Service
- **Build Tool**: Maven with multi-stage Docker builds

### AWS Cloud Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Telegram API  │    │   ChatGPT API   │    │   AWS Secrets   │
│                 │    │                 │    │    Manager      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   ECS Fargate   │
                    │   (Container)   │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   RDS MySQL     │
                    │   (Database)    │
                    └─────────────────┘
```

**Components:**
- **ECS Fargate**: Container orchestration for the application
- **RDS MySQL**: Managed database for message tracking
- **Secrets Manager**: Secure storage for API keys and credentials
- **ECR**: Docker image registry
- **CloudWatch**: Logging and monitoring
- **VPC**: Network isolation with public/private subnets
- **IAM**: Role-based access control

## 📋 Prerequisites

- Java 17 or higher
- Maven 3.6+
- Docker and Docker Compose
- AWS CLI (for cloud deployment)
- Terraform (for infrastructure deployment)
- Telegram Bot Token (from [@BotFather](https://t.me/botfather))
- ChatGPT API credentials

## 🛠️ Local Development Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd telegram-ai-chatbot
```

### 2. Environment Configuration
Create a `.env.local` file with your configuration:
```bash
# Database
DB_USERNAME=local
DB_PASSWORD=local
DB_HOST=localhost
DB_PORT=3306
DB_NAME=telegram_bot_db

# Telegram Bot
TELEGRAM_USERNAME=your_bot_username
TELEGRAM_TOKEN=your_telegram_bot_token

# ChatGPT API
CHATGPT_URL=https://genai.hkbu.edu.hk/general/rest
CHATGPT_MODEL=gpt-4-o-mini
CHATGPT_API_VERSION=2024-05-01-preview
CHATGPT_TOKEN=your_chatgpt_api_token
```

### 3. Start Local Environment
```bash
# Option 1: Full Docker environment
./start-docker.sh

# Option 2: Local development with Docker database
./start-local.sh
```

The application will be available at `http://localhost:8080`

## 🐳 Docker Deployment

### Build and Run with Docker Compose
```bash
# Build and start all services
docker compose up -d

# View logs
docker compose logs -f app

# Stop services
docker compose down -v
```

### Multi-Platform Docker Build
```bash
# Build for multiple architectures
docker buildx build --platform linux/amd64,linux/arm64 --target prod -t telegram-ai-chatbot:latest .
```

## ☁️ AWS Cloud Deployment

### 1. Infrastructure Setup

#### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed
- S3 bucket for Terraform state (create manually or use the provided script)

#### Initialize Terraform Backend
```bash
./scripts/terraform-backend.sh
```

#### Configure Variables
Create `infra/terraform.tfvars`:
```hcl
db_username     = "your_db_username"
db_password     = "your_secure_password"
telegram_token  = "your_telegram_bot_token"
telegram_username = "your_bot_username"
chatgpt_token   = "your_chatgpt_api_token"
aws_region      = "ap-east-1"
```

#### Deploy Infrastructure
```bash
./scripts/infra_deploy.sh
```

### 2. Application Deployment

#### Build and Push to ECR
```bash
./scripts/container_deploy.sh
```

#### Monitor Deployment
```bash
# Check ECS service status
aws ecs describe-services \
  --cluster telegram-ai-chatbot-cluster \
  --services telegram-ai-chatbot-service \
  --region ap-east-1

# View CloudWatch logs
aws logs tail /ecs/telegram-ai-chatbot --follow --region ap-east-1
```

### 3. Cleanup
```bash
# Destroy infrastructure
./scripts/infra_destroy.sh

# Clear Docker resources
./scripts/docker_clear_all.sh
```

## 🤖 Bot Usage

### Available Commands
- `/help` - Display help message
- `/add <keyword>` - Track keyword usage count
- Any other message - Get AI-powered response from ChatGPT

### Example Interactions
```
User: Hello, how are you?
Bot: Hello! I'm doing well, thank you for asking. How can I assist you today?

User: /add coffee
Bot: You have said coffee for 1 times.

User: /add coffee
Bot: You have said coffee for 2 times.
```

## 📁 Project Structure

```
telegram-ai-chatbot/
├── src/main/java/com/example/
│   ├── config/
│   │   ├── ChatbotProperties.java      # Configuration properties
│   │   └── TelegramBotConfig.java      # Bot configuration
│   ├── controller/
│   │   └── MyTelegramBot.java          # Main bot controller
│   ├── entity/
│   │   └── MessageCount.java           # Database entity
│   ├── repository/
│   │   └── MessageCountRepository.java # Data access layer
│   ├── service/
│   │   └── ChatGPTService.java         # AI service integration
│   └── TelegramAIBotApp.java           # Application entry point
├── src/main/resources/
│   ├── application.properties          # Base configuration
│   ├── application-local.properties    # Local environment
│   ├── application-docker.properties   # Docker environment
│   └── application-prod.properties     # Production environment
├── infra/
│   ├── main.tf                         # Terraform infrastructure
│   ├── variables.tf                    # Terraform variables
│   ├── outputs.tf                      # Terraform outputs
│   └── task-definitions.json           # ECS task definition
├── scripts/
│   ├── infra_deploy.sh                 # Infrastructure deployment
│   ├── container_deploy.sh             # Application deployment
│   ├── infra_destroy.sh                # Infrastructure cleanup
│   ├── docker_clear_all.sh             # Docker cleanup
│   └── terraform-backend.sh            # Terraform backend setup
├── docker-compose.yml                  # Local Docker setup
├── Dockerfile                          # Multi-stage Docker build
├── pom.xml                             # Maven configuration
└── README.md                           # This file
```

## 🔧 Configuration

### Environment Variables
| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DB_USERNAME` | Database username | Yes | - |
| `DB_PASSWORD` | Database password | Yes | - |
| `DB_HOST` | Database host | Yes | localhost |
| `DB_PORT` | Database port | No | 3306 |
| `DB_NAME` | Database name | No | telegram_bot_db |
| `TELEGRAM_USERNAME` | Bot username | Yes | - |
| `TELEGRAM_TOKEN` | Bot token | Yes | - |
| `CHATGPT_URL` | ChatGPT API URL | Yes | - |
| `CHATGPT_MODEL` | AI model name | No | gpt-4-o-mini |
| `CHATGPT_API_VERSION` | API version | No | 2024-05-01-preview |
| `CHATGPT_TOKEN` | ChatGPT API token | Yes | - |

### Spring Profiles
- `local` - Local development with embedded database
- `docker` - Docker environment
- `prod` - Production AWS environment

## 🔒 Security

- All sensitive data stored in AWS Secrets Manager
- Database access restricted to ECS security group
- VPC isolation with private subnets
- IAM roles with minimal required permissions
- Environment-based configuration management

## 📊 Monitoring and Logging

- **CloudWatch Logs**: Application logs with 30-day retention
- **ECS Service Monitoring**: Task health and performance metrics
- **RDS Monitoring**: Database performance and health
- **Structured Logging**: JSON-formatted logs for easy parsing

## 🚀 Performance

- **Container Optimization**: Multi-stage Docker builds
- **Database Optimization**: Connection pooling and query optimization
- **Caching**: Spring Boot's built-in caching mechanisms
- **Auto-scaling**: ECS Fargate with configurable CPU/memory

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the logs in CloudWatch (for production deployments)
- Review the configuration files for common setup issues

## 🔄 Version History

- **v1.0.0** - Initial release with basic ChatGPT integration and message tracking
- Features: Telegram bot, ChatGPT API integration, MySQL persistence, AWS deployment