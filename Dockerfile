# Stage 1: Build the application
FROM --platform=linux/amd64 eclipse-temurin:17-jdk-jammy AS builder
WORKDIR /workspace/app

# Copy build files
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN ./mvnw dependency:go-offline -B

# Build the application
COPY src src
RUN ./mvnw package -DskipTests

# Stage 2: Run the application (for non-prod, e.g., local Docker or dev)
FROM --platform=linux/amd64 eclipse-temurin:17-jre-jammy AS docker
WORKDIR /app

# Copy the Spring Boot layered JAR
COPY --from=builder /workspace/app/target/*.jar app.jar

# Proper entrypoint for Spring Boot fat JAR with 'docker' profile
ENTRYPOINT ["java", "-Dspring.profiles.active=docker", "-jar", "app.jar"]

# Stage 3: Run the application (for production)
FROM --platform=linux/amd64 eclipse-temurin:17-jre-jammy AS prod
WORKDIR /app

# Copy the Spring Boot layered JAR
COPY --from=builder /workspace/app/target/*.jar app.jar

# Production
ENTRYPOINT ["java", "-Dspring.profiles.active=prod", "-jar", "app.jar"]