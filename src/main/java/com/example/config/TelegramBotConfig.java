package com.example.config;

import com.example.controller.MyTelegramBot;
import com.example.repository.MessageCountRepository;
import com.example.service.ChatGPTService;
import lombok.Getter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.telegram.telegrambots.bots.DefaultBotOptions;
import org.telegram.telegrambots.meta.TelegramBotsApi;
import org.telegram.telegrambots.meta.exceptions.TelegramApiException;
import org.telegram.telegrambots.updatesreceivers.DefaultBotSession;

@Configuration
@Getter
public class TelegramBotConfig {
    @Autowired
    private ChatbotProperties chatbotProperties;

    @Autowired
    private ChatGPTService chatGPTService;

    @Autowired
    private MessageCountRepository messageCountRepository;

    @Bean
    public DefaultBotOptions defaultBotOptions() {
        return new DefaultBotOptions();
    }

    @Bean
    public TelegramBotsApi telegramBotsApi() throws TelegramApiException {
        MyTelegramBot myTelegramBot = new MyTelegramBot(chatbotProperties, chatGPTService, messageCountRepository);
        TelegramBotsApi telegramBotsApi = new TelegramBotsApi(DefaultBotSession.class);
        telegramBotsApi.registerBot(myTelegramBot);
        return telegramBotsApi;
    }
}