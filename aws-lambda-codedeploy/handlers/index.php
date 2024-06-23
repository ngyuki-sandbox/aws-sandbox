<?php
return function ($payload) {
    if (is_array($payload) && isset($payload['error'])) {
        throw new RuntimeException($payload['error']);
    }
    return [
        'statusCode' => 200,
        'headers' => [
            'Content-Type' => 'text/plain',
            'x-php-version' => PHP_VERSION,
        ],
        'body' => [
            'version' => getenv('VERSION'),
            'payload' => $payload,
        ],
    ];
};
