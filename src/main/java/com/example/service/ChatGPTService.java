package com.example.service;

import com.example.config.BotConfig;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class ChatGPTService {
    private static final Logger logger = LoggerFactory.getLogger(ChatGPTService.class);
    private final BotConfig botConfig;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public ChatGPTService(BotConfig botConfig) {
        this.botConfig = botConfig;
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    public String submit(String message) {
        try {
            String url = buildUrl();
            HttpEntity<String> entity = createRequestEntity(message);

            logger.debug("Sending request to ChatGPT API with URL: {}", url);
            logger.debug("Request headers: {}", entity.getHeaders());

            ResponseEntity<String> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    entity,
                    String.class);

            if (response.getStatusCode() == HttpStatus.OK) {
                String responseBody = response.getBody();
                logger.debug("Received response: {}", responseBody);

                if (responseBody != null && responseBody.startsWith("{")) {
                    JsonNode root = objectMapper.readTree(responseBody);
                    return root.path("choices").get(0)
                            .path("message")
                            .path("content")
                            .asText();
                } else {
                    logger.error("Invalid response format: {}", responseBody);
                    return "Error: Invalid response format";
                }
            } else {
                logger.error("API request failed with status: {}", response.getStatusCode());
                return "Error: " + response.getStatusCode();
            }
        } catch (Exception e) {
            logger.error("Error processing ChatGPT request", e);
            return "Error: " + e.getMessage();
        }
    }

    private String buildUrl() {
        return String.format("%s/deployments/%s/chat/completions?api-version=%s",
                botConfig.getChatgptUrl(),
                botConfig.getChatgptModel(),
                botConfig.getChatgptApiVersion());
    }

    private HttpEntity<String> createRequestEntity(String message) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("api-key", botConfig.getChatgptToken()); // This sets the API key in headers

        String payload = String.format(
                "{\"messages\": [{\"role\": \"user\", \"content\": \"%s\"}]}",
                escapeJson(message));

        logger.debug("Request payload: {}", payload);
        return new HttpEntity<>(payload, headers);
    }

    private String escapeJson(String input) {
        if (input == null) return "";
        return input.replace("\"", "\\\"")
                .replace("\\", "\\\\")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}