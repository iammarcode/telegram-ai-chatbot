package com.example.controller;

import com.example.config.ChatbotProperties;
import com.example.entity.MessageCount;
import com.example.repository.MessageCountRepository;
import com.example.service.ChatGPTService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.telegram.telegrambots.bots.TelegramLongPollingBot;
import org.telegram.telegrambots.meta.api.methods.send.SendMessage;
import org.telegram.telegrambots.meta.api.objects.Update;
import org.telegram.telegrambots.meta.exceptions.TelegramApiException;

@Component
public class MyTelegramBot extends TelegramLongPollingBot {
    private static final Logger logger = LoggerFactory.getLogger(MyTelegramBot.class);

    private final ChatbotProperties chatbotProperties;

    private final ChatGPTService chatGPTService;

    private final MessageCountRepository messageCountRepository;

    public MyTelegramBot(ChatbotProperties chatbotProperties, ChatGPTService chatGPTService, MessageCountRepository messageCountRepository) {
        super(chatbotProperties.getTelegramToken());
        this.chatbotProperties = chatbotProperties;
        this.chatGPTService = chatGPTService;
        this.messageCountRepository = messageCountRepository;
    }

    @Override
    public String getBotUsername() {
        return chatbotProperties.getTelegramUsername();
    }


    @Override
    public void onUpdateReceived(Update update) {
        if (update.hasMessage() && update.getMessage().hasText()) {
            String messageText = update.getMessage().getText();
            long chatId = update.getMessage().getChatId();

            try {
                if (messageText.startsWith("/add")) {
                    handleAddCommand(messageText, chatId);
                } else if (messageText.startsWith("/help")) {
                    sendMessage(chatId, "Helping you helping you.");
                } else {
                    String response = chatGPTService.submit(messageText);
                    sendMessage(chatId, response);
                }
            } catch (TelegramApiException e) {
                logger.error("Error processing update: ", e);
            }
        }
    }

    private void handleAddCommand(String messageText, long chatId) throws TelegramApiException {
        String[] parts = messageText.split("\\s+", 2);
        if (parts.length < 2) {
            sendMessage(chatId, "Usage: /add <keyword>");
            return;
        }

        String keyword = parts[1];
        MessageCount count = messageCountRepository.findByKeyword(keyword)
                .orElse(MessageCount.builder().keyword(keyword).count(0L).build());
        count.setCount(count.getCount() + 1);
        messageCountRepository.save(count);

        sendMessage(chatId, "You have said " + keyword + " for " + count.getCount() + " times.");
    }

    private void sendMessage(long chatId, String text) throws TelegramApiException {
        SendMessage message = new SendMessage();
        message.setChatId(String.valueOf(chatId));
        message.setText(text);
        execute(message);
    }
}