package com.example.repository;

import com.example.entity.MessageCount;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MessageCountRepository extends JpaRepository<MessageCount, String> {
}