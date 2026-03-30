package com.buzzer.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String CHAT_DIRECT_EXCHANGE = "chat.direct";
    public static final String CHAT_GROUP_EXCHANGE = "chat.group";
    public static final String CHAT_DLX_EXCHANGE = "chat.dlx";
    public static final String NOTIFICATIONS_EXCHANGE = "notifications";

    // Queues
    public static final String USER_MESSAGES_QUEUE_PREFIX = "user.";
    public static final String NOTIFICATIONS_QUEUE = "notifications";

    @Bean
    public TopicExchange chatDirectExchange() {
        return new TopicExchange(CHAT_DIRECT_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange chatGroupExchange() {
        return new TopicExchange(CHAT_GROUP_EXCHANGE, true, false);
    }

    @Bean
    public DirectExchange chatDlxExchange() {
        return new DirectExchange(CHAT_DLX_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange notificationsExchange() {
        return new TopicExchange(NOTIFICATIONS_EXCHANGE, true, false);
    }

    @Bean
    public Queue notificationsQueue() {
        return QueueBuilder.durable(NOTIFICATIONS_QUEUE)
                .build();
    }

    @Bean
    public Binding notificationsBinding(Queue notificationsQueue, TopicExchange notificationsExchange) {
        return BindingBuilder.bind(notificationsQueue)
                .to(notificationsExchange)
                .with("notification.#");
    }

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory, MessageConverter jsonMessageConverter) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(jsonMessageConverter);
        return template;
    }
}