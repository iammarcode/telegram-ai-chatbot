package com.example.config;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "bot")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class BotProperties {
    // bot
    private String token;
    private String username;

    // gpt
    private String chatgptUrl;
    private String chatgptModel;
    private String chatgptApiVersion;
    private String chatgptToken;
}