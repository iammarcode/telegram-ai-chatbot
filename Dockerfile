# Stage 1: Build the application
FROM eclipse-temurin:17-jdk-jammy as builder
WORKDIR /workspace/app

# Copy build files
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN ./mvnw dependency:go-offline -B

# Build the application
COPY src src
RUN ./mvnw package -DskipTests

# Stage 2: Run the application
FROM eclipse-temurin:17-jre-jammy as docker
WORKDIR /app

# Copy the Spring Boot layered JAR
COPY --from=builder /workspace/app/target/*.jar app.jar

# Proper entrypoint for Spring Boot fat JAR
ENTRYPOINT ["java", "-Dspring.profiles.active=docker", "-jar", "app.jar"]