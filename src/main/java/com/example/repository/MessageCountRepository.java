package com.example.repository;

import com.example.entity.MessageCount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MessageCountRepository extends JpaRepository<MessageCount, String> {
}