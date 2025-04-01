package com.example.repository;

import com.example.entity.MessageCount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MessageCountRepository extends JpaRepository<MessageCount, String> {
    Optional<MessageCount> findByKeyword(String keyword);
}