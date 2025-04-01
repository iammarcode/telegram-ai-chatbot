package com.example.service;

import com.example.config.BotConfig;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class ChatGPTService {
    private final BotConfig botConfig;
    private final RestTemplate restTemplate;

    public ChatGPTService(BotConfig botConfig) {
        this.botConfig = botConfig;
        this.restTemplate = new RestTemplate();
    }

    public String submit(String message) {
        String url = botConfig.getChatgptUrl() + "/deployments/" +
                botConfig.getChatgptModel() + "/chat/completions/?api-version=" +
                botConfig.getChatgptApiVersion();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("api-key", botConfig.getChatgptToken());

        String payload = "{\"messages\": [{\"role\": \"user\", \"content\": \"" + message + "\"}]}";
        HttpEntity<String> entity = new HttpEntity<>(payload, headers);

        try {
            String response = restTemplate.postForObject(url, entity, String.class);
            // Simple parsing - in production, use proper JSON parsing
            return response != null ? response.split("\"content\":\"")[1].split("\"")[0] : "Error processing response";
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }
}