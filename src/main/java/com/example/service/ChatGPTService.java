package com.example.service;

import com.example.config.ChatbotProperties;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ChatGPTService {
    private static final Logger logger = LoggerFactory.getLogger(ChatGPTService.class);
    private final ChatbotProperties chatbotProperties;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public ChatGPTService(ChatbotProperties chatbotProperties) {
        this.chatbotProperties = chatbotProperties;
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    public String submit(String message) {
        try {
            String url = String.format("%s/deployments/%s/chat/completions?api-version=%s",
                    chatbotProperties.getChatgptUrl(),
                    chatbotProperties.getChatgptModel(),
                    chatbotProperties.getChatgptApiVersion());

            HttpEntity<Map<String, Object>> request = createRequestEntity(message);

            logger.debug("telegram-ai-chatbot - Sending request to ChatGPT API with URL: {}", url);
            logger.debug("telegram-ai-chatbot - Request headers: {}", request.getHeaders());

            ResponseEntity<String> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    request,
                    String.class);

            if (response.getStatusCode() == HttpStatus.OK) {
                String responseBody = response.getBody();
                logger.debug("telegram-ai-chatbot - Received response: {}", responseBody);

                if (responseBody != null && responseBody.startsWith("{")) {
                    JsonNode root = objectMapper.readTree(responseBody);
                    return root.path("choices").get(0)
                            .path("message")
                            .path("content")
                            .asText();
                } else {
                    logger.error("telegram-ai-chatbot - Invalid response format: {}", responseBody);
                    return "Error: Invalid response format";
                }
            } else {
                logger.error("telegram-ai-chatbot - API request failed with status: {}", response.getStatusCode());
                return "Error: " + response.getStatusCode();
            }
        } catch (Exception e) {
            logger.error("telegram-ai-chatbot - Error processing ChatGPT request", e);
            return "Error: " + e.getMessage();
        }
    }

    private HttpEntity<Map<String, Object>> createRequestEntity(String message) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("api-key", chatbotProperties.getChatgptToken()); // This sets the API key in headers

        Map<String, Object> payload = new HashMap<>();
        Map<String, String> messageMap = new HashMap<>();

        messageMap.put("role", "user");
        messageMap.put("content", message);

        payload.put("messages", List.of(messageMap));

        logger.debug("telegram-ai-chatbot - Request payload: {}", payload);
        return new HttpEntity<>(payload, headers);
    }
}